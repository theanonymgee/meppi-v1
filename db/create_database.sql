CREATE TABLE IF NOT EXISTS phones (
  id SERIAL PRIMARY KEY,
  brand VARCHAR(255),
  model VARCHAR(255),
  screen_size VARCHAR(255),
  battery VARCHAR(255),
  camera VARCHAR(255),
  storage VARCHAR(255),
  created_at TIMESTAMP WITHOUT TIME ZONE,
  updated_at TIMESTAMP WITHOUT TIME ZONE,
  country_id INTEGER,
  price_usd MONEY
);
