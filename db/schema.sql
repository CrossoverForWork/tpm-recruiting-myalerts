--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: add_etl_updated_load_date(); Type: FUNCTION; Schema: public; Owner: tifadmin
--

CREATE FUNCTION add_etl_updated_load_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NEW.etl_updated_load_date := current_timestamp;
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.add_etl_updated_load_date() OWNER TO tifadmin;

--
-- Name: uniq(anyarray); Type: FUNCTION; Schema: public; Owner: tifadmin
--

CREATE FUNCTION uniq(anyarray) RETURNS anyarray
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
select array(select distinct $1[i] from
generate_series(array_lower($1,1), array_upper($1,1)) g(i));
$_$;


ALTER FUNCTION public.uniq(anyarray) OWNER TO tifadmin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE alerts (
    id integer NOT NULL,
    template text NOT NULL,
    data text NOT NULL,
    priority integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    dispatched_at timestamp without time zone,
    type text,
    user_id integer,
    match_types text,
    etl_updated_load_date timestamp without time zone
);


ALTER TABLE alerts OWNER TO tifadmin;

--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: tifadmin
--

CREATE SEQUENCE alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alerts_id_seq OWNER TO tifadmin;

--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tifadmin
--

ALTER SEQUENCE alerts_id_seq OWNED BY alerts.id;


--
-- Name: alerts_trackers; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE alerts_trackers (
    alert_id integer,
    tracker_id integer
);


ALTER TABLE alerts_trackers OWNER TO tifadmin;

--
-- Name: contact_methods; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE contact_methods (
    user_id integer,
    label text NOT NULL,
    entry text NOT NULL,
    enabled boolean,
    status text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE contact_methods OWNER TO tifadmin;

--
-- Name: item_records; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE item_records (
    id integer NOT NULL,
    item_id integer,
    data text NOT NULL,
    digest text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    etl_updated_load_date timestamp without time zone
);


ALTER TABLE item_records OWNER TO tifadmin;

--
-- Name: item_records_id_seq; Type: SEQUENCE; Schema: public; Owner: tifadmin
--

CREATE SEQUENCE item_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE item_records_id_seq OWNER TO tifadmin;

--
-- Name: item_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tifadmin
--

ALTER SEQUENCE item_records_id_seq OWNED BY item_records.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE items (
    id integer NOT NULL,
    url text NOT NULL,
    type text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    requested_at timestamp without time zone,
    data hstore,
    mongoid text,
    items_mongoids hstore,
    parse_in_progress boolean DEFAULT false,
    parse_started_date timestamp without time zone,
    parse_expiration_date timestamp without time zone,
    parse_next_date timestamp without time zone,
    domain_name text,
    etl_updated_load_date timestamp without time zone,
    uuid text,
    client_identifier text,
    status text,
    failed_parses integer DEFAULT 0,
    last_time_parsed timestamp without time zone
);


ALTER TABLE items OWNER TO tifadmin;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: tifadmin
--

CREATE SEQUENCE items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE items_id_seq OWNER TO tifadmin;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tifadmin
--

ALTER SEQUENCE items_id_seq OWNED BY items.id;


--
-- Name: lists; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE lists (
    id integer NOT NULL,
    user_id integer,
    name text NOT NULL,
    slug text NOT NULL,
    meta text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    requested_at timestamp without time zone,
    mongoid text,
    etl_updated_load_date timestamp without time zone
);


ALTER TABLE lists OWNER TO tifadmin;

--
-- Name: lists_id_seq; Type: SEQUENCE; Schema: public; Owner: tifadmin
--

CREATE SEQUENCE lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE lists_id_seq OWNER TO tifadmin;

--
-- Name: lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tifadmin
--

ALTER SEQUENCE lists_id_seq OWNED BY lists.id;


--
-- Name: mapping; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE mapping (
    old_id integer,
    new_id integer,
    url text
);


ALTER TABLE mapping OWNER TO tifadmin;

--
-- Name: matches; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE matches (
    id integer NOT NULL,
    tracker_id integer,
    alert_id integer,
    name text NOT NULL,
    data text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    mongoid text,
    user_id integer,
    etl_updated_load_date timestamp without time zone
);


ALTER TABLE matches OWNER TO tifadmin;

--
-- Name: matches_id_seq; Type: SEQUENCE; Schema: public; Owner: tifadmin
--

CREATE SEQUENCE matches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE matches_id_seq OWNER TO tifadmin;

--
-- Name: matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tifadmin
--

ALTER SEQUENCE matches_id_seq OWNED BY matches.id;

--
-- Name: schema_info; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE schema_info (
    version integer DEFAULT 0 NOT NULL
);


ALTER TABLE schema_info OWNER TO tifadmin;

--
-- Name: templates; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE templates (
    id integer NOT NULL,
    name text NOT NULL,
    custom_css text NOT NULL,
    erb text NOT NULL,
    locals text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE templates OWNER TO tifadmin;

--
-- Name: templates_id_seq; Type: SEQUENCE; Schema: public; Owner: tifadmin
--

CREATE SEQUENCE templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE templates_id_seq OWNER TO tifadmin;

--
-- Name: templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tifadmin
--

ALTER SEQUENCE templates_id_seq OWNED BY templates.id;


--
-- Name: trackers; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE trackers (
    id integer NOT NULL,
    list_id integer,
    item_id integer,
    triggers text NOT NULL,
    notification_methods text NOT NULL,
    meta text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    requested_at timestamp without time zone,
    mongoid text,
    last_record_digest text,
    tags text,
    user_id integer,
    external_triggers boolean DEFAULT false,
    internal_triggers boolean DEFAULT false,
    parent_tracker integer,
    etl_updated_load_date timestamp without time zone,
    status text
);


ALTER TABLE trackers OWNER TO tifadmin;

--
-- Name: trackers_id_seq; Type: SEQUENCE; Schema: public; Owner: tifadmin
--

CREATE SEQUENCE trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE trackers_id_seq OWNER TO tifadmin;

--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tifadmin
--

ALTER SEQUENCE trackers_id_seq OWNED BY trackers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: tifadmin
--

CREATE TABLE users (
    id integer NOT NULL,
    user_identifier text NOT NULL,
    client_identifier text NOT NULL,
    client_api_key text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    requested_at timestamp without time zone,
    mongoid text,
    meta text,
    etl_updated_load_date timestamp without time zone
);


ALTER TABLE users OWNER TO tifadmin;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: tifadmin
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO tifadmin;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tifadmin
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY alerts ALTER COLUMN id SET DEFAULT nextval('alerts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY item_records ALTER COLUMN id SET DEFAULT nextval('item_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY items ALTER COLUMN id SET DEFAULT nextval('items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY lists ALTER COLUMN id SET DEFAULT nextval('lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY matches ALTER COLUMN id SET DEFAULT nextval('matches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY templates ALTER COLUMN id SET DEFAULT nextval('templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY trackers ALTER COLUMN id SET DEFAULT nextval('trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: item_records_pkey; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY item_records
    ADD CONSTRAINT item_records_pkey PRIMARY KEY (id);


--
-- Name: items_pkey; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: lists_pkey; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY lists
    ADD CONSTRAINT lists_pkey PRIMARY KEY (id);


--
-- Name: lists_user_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY lists
    ADD CONSTRAINT lists_user_id_slug_key UNIQUE (user_id, slug);


--
-- Name: matches_pkey; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (id);


--
-- Name: templates_pkey; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id);


--
-- Name: trackers_list_id_item_id_key; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_list_id_item_id_key UNIQUE (list_id, item_id);


--
-- Name: trackers_pkey; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);


--
-- Name: users_client_identifier_user_identifier_key; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_client_identifier_user_identifier_key UNIQUE (client_identifier, user_identifier);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: alerts_etl_updated_load_date_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX alerts_etl_updated_load_date_index ON alerts USING btree (etl_updated_load_date);


--
-- Name: alerts_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX alerts_id_index ON alerts USING btree (id);


--
-- Name: alerts_match_types_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX alerts_match_types_index ON alerts USING btree (match_types);


--
-- Name: alerts_trackers_alert_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX alerts_trackers_alert_id_index ON alerts_trackers USING btree (alert_id);


--
-- Name: alerts_trackers_alert_id_tracker_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX alerts_trackers_alert_id_tracker_id_index ON alerts_trackers USING btree (alert_id, tracker_id);


--
-- Name: alerts_user_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX alerts_user_id_index ON alerts USING btree (user_id);


--
-- Name: contact_methods_user_id_method_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX contact_methods_user_id_method_index ON contact_methods USING btree (user_id, label);


--
-- Name: item_records_etl_updated_load_date_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX item_records_etl_updated_load_date_index ON item_records USING btree (etl_updated_load_date);


--
-- Name: item_records_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX item_records_id_index ON item_records USING btree (id);


--
-- Name: item_records_item_id_digest_requested_at_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX item_records_item_id_digest_requested_at_index ON item_records USING btree (item_id, digest, requested_at);


--
-- Name: item_records_item_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX item_records_item_id_index ON item_records USING btree (item_id);


--
-- Name: items_etl_updated_load_date_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX items_etl_updated_load_date_index ON items USING btree (etl_updated_load_date);


--
-- Name: items_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX items_id_index ON items USING btree (id);


--
-- Name: items_mongoid_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX items_mongoid_index ON items USING btree (mongoid);


--
-- Name: items_status_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX items_status_index ON items USING btree (status);


--
-- Name: items_type_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX items_type_index ON items USING btree (type);


--
-- Name: items_url_idx; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX items_url_idx ON items USING btree (url);


--
-- Name: items_uuid_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX items_uuid_index ON items USING btree (uuid);


--
-- Name: lists_etl_updated_load_date_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX lists_etl_updated_load_date_index ON lists USING btree (etl_updated_load_date);


--
-- Name: lists_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX lists_id_index ON lists USING btree (id);


--
-- Name: lists_mongoid_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX lists_mongoid_index ON lists USING btree (mongoid);


--
-- Name: lists_user_id_slug_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX lists_user_id_slug_index ON lists USING btree (user_id, slug);


--
-- Name: matches_alert_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX matches_alert_id_index ON matches USING btree (alert_id);


--
-- Name: matches_etl_updated_load_date_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX matches_etl_updated_load_date_index ON matches USING btree (etl_updated_load_date);


--
-- Name: matches_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX matches_id_index ON matches USING btree (id);


--
-- Name: matches_tracker_id_alert_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX matches_tracker_id_alert_id_index ON matches USING btree (tracker_id, alert_id);


--
-- Name: matches_tracker_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX matches_tracker_id_index ON matches USING btree (tracker_id);


--
-- Name: matches_user_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX matches_user_id_index ON matches USING btree (user_id);


--
-- Name: templates_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX templates_id_index ON templates USING btree (id);


--
-- Name: trackers_etl_updated_load_date_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX trackers_etl_updated_load_date_index ON trackers USING btree (etl_updated_load_date);


--
-- Name: trackers_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX trackers_id_index ON trackers USING btree (id);


--
-- Name: trackers_item_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX trackers_item_id_index ON trackers USING btree (item_id);


--
-- Name: trackers_item_id_list_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX trackers_item_id_list_id_index ON trackers USING btree (item_id, list_id);


--
-- Name: trackers_mongoid_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX trackers_mongoid_index ON trackers USING btree (mongoid);


--
-- Name: trackers_parent_tracker_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX trackers_parent_tracker_index ON trackers USING btree (parent_tracker);


--
-- Name: trackers_user_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX trackers_user_id_index ON trackers USING btree (user_id);


--
-- Name: users_client_identifier_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX users_client_identifier_index ON users USING btree (client_identifier);


--
-- Name: users_etl_updated_load_date_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX users_etl_updated_load_date_index ON users USING btree (etl_updated_load_date);


--
-- Name: users_id_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX users_id_index ON users USING btree (id);


--
-- Name: users_mongoid_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX users_mongoid_index ON users USING btree (mongoid);


--
-- Name: users_user_identifier_client_identifier_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE UNIQUE INDEX users_user_identifier_client_identifier_index ON users USING btree (user_identifier, client_identifier);


--
-- Name: users_user_identifier_index; Type: INDEX; Schema: public; Owner: tifadmin
--

CREATE INDEX users_user_identifier_index ON users USING btree (user_identifier);


--
-- Name: alerts_add_etl_updated_load_date; Type: TRIGGER; Schema: public; Owner: tifadmin
--

CREATE TRIGGER alerts_add_etl_updated_load_date BEFORE INSERT OR UPDATE ON alerts FOR EACH ROW EXECUTE PROCEDURE add_etl_updated_load_date();


--
-- Name: item_records_add_etl_updated_load_date; Type: TRIGGER; Schema: public; Owner: tifadmin
--

CREATE TRIGGER item_records_add_etl_updated_load_date BEFORE INSERT OR UPDATE ON item_records FOR EACH ROW EXECUTE PROCEDURE add_etl_updated_load_date();


--
-- Name: items_add_etl_updated_load_date; Type: TRIGGER; Schema: public; Owner: tifadmin
--

CREATE TRIGGER items_add_etl_updated_load_date BEFORE INSERT OR UPDATE ON items FOR EACH ROW EXECUTE PROCEDURE add_etl_updated_load_date();


--
-- Name: lists_add_etl_updated_load_date; Type: TRIGGER; Schema: public; Owner: tifadmin
--

CREATE TRIGGER lists_add_etl_updated_load_date BEFORE INSERT OR UPDATE ON lists FOR EACH ROW EXECUTE PROCEDURE add_etl_updated_load_date();


--
-- Name: matches_add_etl_updated_load_date; Type: TRIGGER; Schema: public; Owner: tifadmin
--

CREATE TRIGGER matches_add_etl_updated_load_date BEFORE INSERT OR UPDATE ON matches FOR EACH ROW EXECUTE PROCEDURE add_etl_updated_load_date();


--
-- Name: trackers_add_etl_updated_load_date; Type: TRIGGER; Schema: public; Owner: tifadmin
--

CREATE TRIGGER trackers_add_etl_updated_load_date BEFORE INSERT OR UPDATE ON trackers FOR EACH ROW EXECUTE PROCEDURE add_etl_updated_load_date();


--
-- Name: users_add_etl_updated_load_date; Type: TRIGGER; Schema: public; Owner: tifadmin
--

CREATE TRIGGER users_add_etl_updated_load_date BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE add_etl_updated_load_date();


--
-- Name: alerts_trackers_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY alerts_trackers
    ADD CONSTRAINT alerts_trackers_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES alerts(id);


--
-- Name: alerts_trackers_tracker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY alerts_trackers
    ADD CONSTRAINT alerts_trackers_tracker_id_fkey FOREIGN KEY (tracker_id) REFERENCES trackers(id);


--
-- Name: contact_methods_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY contact_methods
    ADD CONSTRAINT contact_methods_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: item_records_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY item_records
    ADD CONSTRAINT item_records_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- Name: lists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY lists
    ADD CONSTRAINT lists_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: matches_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY matches
    ADD CONSTRAINT matches_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES alerts(id);


--
-- Name: matches_tracker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY matches
    ADD CONSTRAINT matches_tracker_id_fkey FOREIGN KEY (tracker_id) REFERENCES trackers(id);


--
-- Name: trackers_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);


--
-- Name: trackers_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tifadmin
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_list_id_fkey FOREIGN KEY (list_id) REFERENCES lists(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: tifadmin
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM tifadmin;
GRANT ALL ON SCHEMA public TO tifadmin;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--
