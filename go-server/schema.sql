CREATE TABLE podcasts
(
    id SERIAL,
    name TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT podcasts_pkey PRIMARY KEY (id)
)
