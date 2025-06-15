+++
title = "Form helper for axum"
date = 2025-06-15
updated = 2025-06-15
description = "New crate for dealing with forms in axum"
authors = ["Behemoth"]
+++

## Form Fields

While working on a personal project that involves a website for configuring some data,
I've grown annoyed by writing the same bad code again and again for every POST-Endpoint.
Form validation is annoying to get "right".

I've already decided to use rust with axum for the web server and maud as the rendering part so
the rough constraints were set.
This was not supposed to be an eierlegende Wollmilchsau and the client site is limited to what is
possible with 2025 baselevel HTML.

Experimenting a bit, I've decided to go with a derive macro, which implements the structure I
need for displaying and validation.

```rs
#[derive(FromForm)]
struct InputData {
    #[text_field(display_name = "Name", max_length = 50)]
    pub name: String,

    #[number_field(display_name = "Age (0-120)", min = 0, max = 120)]
    pub age: Option<u8>,

    /* ... */
}
```

The derive-Macro will generate a struct that mimics the original struct closely.
For every field in the original, there will be an equivalent in the new struct.

The `name` field will result in a `FormField<TextField>` which is marked as required,
while `age` will generate a `FormField<NumberField>` which is marked as optional.

This new type can be retrieved from any of our axum handlers. Both `GET` and `POST` should be
routed to the same function.

```rs
async fn simple(method: Method, FromForm(mut form): FromForm<InputData>) -> Response<Body> {
```

The form is populated with all the static settings and on `POST` requests, all the data
will be parsed from either url-encoded or multipart data.

If we'd like to add constraints that aren't static, we can add them here.
```rs
    form.age.descriptor.min = 16;
```

If we are in a `POST` request, we can extract the inner data, which we actually want to deal with.
```rs
    if method == Method::POST {
        if let Some(input) = form.inner() {
            /* Store data and redirect somewhere */
        } else {
            /* Something went wrong, validating the input data */
        }
    }
```

If we allow editing existing data, and we are in a `GET` request,
we might want to populate the form with the data that was already stored on our end.

```rs
    State(db): State<Database>,
    Query(id): Query<PrimaryKey>,
...
    if method == Method::GET {
        let data: InputData = db.load(id).await?;
        form.load(data)
    }
```

To help us render our inputs, implementations for maud's `Render` trait are provided.
```rs
    html! {
        form method="POST" {
            (form.name)
            (form.age)
            input type="submit";
        }
    }
    .into_response()
}
```

If you'd like to try this for yourself or help me expand this or improve the code and ergonomics,
you can find the code [here](https://github.com/HookedBehemoth/axum-form-fields)

I've published it on [crates.io](https://crates.io/crates/form_fields), without the axum prefix,
since I'd imagine I'll want to make this work on other web server implementations.
Allowing other web templating engines would also be cool.
