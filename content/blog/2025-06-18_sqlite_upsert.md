+++
title = "Knowing if you actually did anything with UPSERT (INSERT ... ON CONFLICT(..) DO UPDATE)"
date = 2025-06-18
updated = 2025-06-18
description = "How to know what your UPSERT statement actually accomplished"
authors = ["Behemoth"]
+++

I've recently been collecting some data and stored it in an SQLite database.

Since the primary key isn't mine, I have to use an `UPSERT` statement which updates the existing entities.
For logging purposes it would be nice to know what the operation actually accomplished.

I've looked around and couldn't find a ready done solution but poking at `sqlite` internals I've 
found [last_inserted_rowid()](https://www.sqlite.org/lang_corefunc.html#last_insert_rowid)
which I could compare with the rowid of my entity.

With another `where`, my result is a nice `Option<bool>` which maps to a nice `InsertResult`
that I now use for logging.
```rs
match inserted {
	Some(true) => InsertResult::Inserted,
	Some(false) => InsertResult::Updated,
	None => InsertResult::NoChange,
}
```

Given this table:
```sql
CREATE TABLE dogs(
	id INTEGER PRIMARY KEY,
	name TEXT NOT NULL,
	fans INTEGER NOT NULL,
	owner_id INTEGER);
```

We can construct an sql statement like such:
```sql
INSERT INTO dogs
	(id, name, fans, owner_id)
VALUES (?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
	name = excluded.name,
	fans = excluded.fans,
	owner_id = excluded.owner_id
WHERE
	name != excluded.name OR
	-- fans != excluded.fans OR
	owner_id != excluded.owner_id
RETURNING _rowid_ = last_insert_rowid();
```

The conditions in the where clause will prevent an update and output if the data is the same.
We can choose to ignore updates if only unimportant columns are updated.

This assumes that you switch between entities.
If you keep checking the same entity, `last_insert_rowid()` will keep returning the same rowid.
