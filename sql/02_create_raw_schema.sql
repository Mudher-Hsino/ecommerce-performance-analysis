-- Create a separate schema for tables imported from the original CSV files.
-- IF NOT EXISTS prevents an error if the script is accidentally run again.

CREATE SCHEMA IF NOT EXISTS raw;