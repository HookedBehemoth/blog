+++
title = "Migrating my tag database from sqlite to postgres"
date = 2025-07-27
updated = 2025-07-27
description = "I've recently migrated my tag database to postgres. Here are a few things I had to say about this."
authors = ["Behemoth"]
+++

I'm at the end of my last adventure and now I have a database dump with 700k entries, 300k tags and 20M link entries in my sqlite database.
Working with this data has not been a concern but now I've written a simple website to sift through the data.
Pretty quickly I've noticed that a few scenarios are slow:
* Going to the end of my list (~2 seconds)
* Searching for any amount of tags (~2 seconds)
    * going to the end of that (+4 seconds)
* counting how many entries are tagged

More compilated combined queries took over 30 seconds.

The following test query takes about 8 seconds, just counting still takes over one.
```sql
SELECT e.*
FROM entry e
WHERE 
    -- Must have "test"
    EXISTS (
        SELECT 1
        FROM entry_tags link
        JOIN tags tag ON link.tag_id = tag.id
        WHERE link.entry_id = e.id AND tag.name = 'test'
    )
    -- Must have "beta"
    AND EXISTS (
        SELECT 1
        FROM entry_tags link
        JOIN tags tag ON link.tag_id = tag.id
        WHERE link.entry_id = e.id AND tag.name = 'beta'
    )
    -- Must NOT have "alpha"
    AND NOT EXISTS (
        SELECT 1
        FROM entry_tags link
        JOIN tags tag ON link.tag_id = tag.id
        WHERE link.entry_id = e.id AND tag.name = 'alpha'
    )
```

#### this is currently a prerelease I wanted to get this out asap to send it to people

Slapping more indices all over the place did not help the case but bloated the database from 1.2GB to 1.7GB.

I have hoped that the amount I'm dealing here didn't warrant moving to postgres but alas.
I've installed [pgloader](https://pgloader.io/) and after having to fiddle around with the filename (.sqlite did not work, .db did), I've moved all my data over.
The code changes were not too bad as I've already written very basic queries.

Sadly the performance was still abysmal. I didn't profile enough to list any specifics though.
Thankfully I could now look at the query plan to get to the root of the issue.
Around ninty percent of the execution time was spent in the "Nested Loop Semi Join" from my EXISTS results to the entry table.

# Materialized Views
I've found a materialized view like this to speed up my queries by 10x to 100x while also not blowing up the database size (~+30%).
```sql
CREATE MATERIALIZED VIEW entry_tag_names AS
SELECT t.id AS entry_id, array_agg(tag.name) AS tag_names
FROM entries t
JOIN entry_tags link ON link.entry_id = t.id
JOIN tags tag ON tag.id = link.tag_id
GROUP BY t.id;
```

The queries look a lot nicer than they did before.
The example from above now boils down to the following, which is much nicer to write and understand.
It also only takes ~300ms and ~200ms to count.
```sql
SELECT e.*
FROM entry e
JOIN entry_tag_names tags
    ON tags.entry_id = e.id
WHERE
    'test' = ANY(tag_names)
    AND 'beta' = ANY(tag_names)
    AND NOT ('alpha' = ANY(tag_names));
```

I expect maintenance to be lower than the array solution suggested in Josh Berkus' article about the same thing [https://www.databasesoup.com/2015/01/tag-all-things.html](https://www.databasesoup.com/2015/01/tag-all-things.html) but that remains to be seen.
I'll now move the rest of my program over to psql and clean up the artifacts of the failed optimization strategies.
