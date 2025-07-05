-- Migration: Create events, locations, and pictures tables with timestamp triggers
-- Date: 2025-07-05

-- 1. Create a function to handle created_at and updated_at timestamps
CREATE OR REPLACE FUNCTION set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := COALESCE(NEW.updated_at, NOW());
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.updated_at := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Create events table
CREATE TABLE events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name VARCHAR(255) NOT NULL,
  event_description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- 3. Create locations table
CREATE TABLE locations (
  location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_name VARCHAR NOT NULL,
  location_description TEXT,
  coordinates POINT,
  event_id UUID NOT NULL REFERENCES events(event_id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- 4. Create pictures table
CREATE TABLE pictures (
  picture_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  picture_url TEXT NOT NULL,
  source_type VARCHAR(255) NOT NULL,
  source_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- 5. Attach the trigger to all three tables
CREATE TRIGGER set_timestamp_events
BEFORE INSERT OR UPDATE ON events
FOR EACH ROW EXECUTE FUNCTION set_timestamp();

CREATE TRIGGER set_timestamp_locations
BEFORE INSERT OR UPDATE ON locations
FOR EACH ROW EXECUTE FUNCTION set_timestamp();

CREATE TRIGGER set_timestamp_pictures
BEFORE INSERT OR UPDATE ON pictures
FOR EACH ROW EXECUTE FUNCTION set_timestamp();
