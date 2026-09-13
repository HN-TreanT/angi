CREATE TABLE IF NOT EXISTS places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dish_name TEXT NOT NULL,
  restaurant TEXT NOT NULL,
  address TEXT NOT NULL,
  province_id TEXT NOT NULL,
  district_id TEXT NOT NULL,
  stars SMALLINT NOT NULL CHECK (stars BETWEEN 1 AND 5),
  eat_again BOOLEAN NOT NULL DEFAULT TRUE,
  price INTEGER NOT NULL DEFAULT 50,
  notes TEXT NOT NULL DEFAULT '',
  image INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS places_province_idx ON places (province_id, district_id);
CREATE INDEX IF NOT EXISTS places_created_idx ON places (created_at DESC);
