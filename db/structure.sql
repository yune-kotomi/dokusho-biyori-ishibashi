--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: pgroonga; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgroonga WITH SCHEMA public;


--
-- Name: EXTENSION pgroonga; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgroonga IS 'CJK-ready fast full-text search index based on Groonga';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bot_keywords; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bot_keywords (
    id integer NOT NULL,
    notify_at integer,
    uncertain boolean DEFAULT false,
    tweet_id character varying,
    twitter_user_id character varying,
    sent_keyword_product_id integer[] DEFAULT '{}'::integer[],
    user_keyword_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bot_keywords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bot_keywords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_keywords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bot_keywords_id_seq OWNED BY bot_keywords.id;


--
-- Name: keyword_candicates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE keyword_candicates (
    id integer NOT NULL,
    value text,
    category character varying,
    elements text[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: keyword_candicates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE keyword_candicates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: keyword_candicates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE keyword_candicates_id_seq OWNED BY keyword_candicates.id;


--
-- Name: keyword_products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE keyword_products (
    id integer NOT NULL,
    keyword_id integer,
    product_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: keyword_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE keyword_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: keyword_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE keyword_products_id_seq OWNED BY keyword_products.id;


--
-- Name: keywords; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE keywords (
    id integer NOT NULL,
    value character varying,
    category character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: keywords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE keywords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: keywords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE keywords_id_seq OWNED BY keywords.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE products (
    id integer NOT NULL,
    ean character varying,
    category character varying,
    a_title text,
    a_authors_json text,
    a_manufacturer text,
    a_image_medium text,
    a_image_small text,
    a_url text,
    a_release_date timestamp without time zone,
    a_release_date_fixed boolean DEFAULT true,
    r_title text,
    r_authors_old text,
    r_manufacturer text,
    r_image_medium text,
    r_image_small text,
    r_url text,
    r_release_date timestamp without time zone,
    release_date timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    a_authors text[],
    r_authors text[]
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_id_seq OWNED BY products.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: user_keywords; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_keywords (
    id integer NOT NULL,
    user_id integer,
    keyword_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_keywords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_keywords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_keywords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_keywords_id_seq OWNED BY user_keywords.id;


--
-- Name: user_products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_products (
    id integer NOT NULL,
    user_id integer,
    product_id integer,
    type_name character varying DEFAULT 'search'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tags character varying[]
);


--
-- Name: user_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_products_id_seq OWNED BY user_products.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    domain_name character varying,
    screen_name character varying,
    nickname character varying,
    profile_text text,
    kitaguchi_profile_id integer,
    random_url boolean DEFAULT false,
    random_key character varying,
    private boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tags jsonb,
    profile_image character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bot_keywords ALTER COLUMN id SET DEFAULT nextval('bot_keywords_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY keyword_candicates ALTER COLUMN id SET DEFAULT nextval('keyword_candicates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY keyword_products ALTER COLUMN id SET DEFAULT nextval('keyword_products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY keywords ALTER COLUMN id SET DEFAULT nextval('keywords_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY products ALTER COLUMN id SET DEFAULT nextval('products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_keywords ALTER COLUMN id SET DEFAULT nextval('user_keywords_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_products ALTER COLUMN id SET DEFAULT nextval('user_products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: bot_keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bot_keywords
    ADD CONSTRAINT bot_keywords_pkey PRIMARY KEY (id);


--
-- Name: keyword_candicates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY keyword_candicates
    ADD CONSTRAINT keyword_candicates_pkey PRIMARY KEY (id);


--
-- Name: keyword_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY keyword_products
    ADD CONSTRAINT keyword_products_pkey PRIMARY KEY (id);


--
-- Name: keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY keywords
    ADD CONSTRAINT keywords_pkey PRIMARY KEY (id);


--
-- Name: products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: user_keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_keywords
    ADD CONSTRAINT user_keywords_pkey PRIMARY KEY (id);


--
-- Name: user_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_products
    ADD CONSTRAINT user_products_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_keyword_candicates_on_value; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_keyword_candicates_on_value ON keyword_candicates USING pgroonga (value);


--
-- Name: index_keyword_products_on_product_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_keyword_products_on_product_id ON keyword_products USING btree (product_id);


--
-- Name: index_products_on_a_authors; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_a_authors ON products USING pgroonga (a_authors);


--
-- Name: index_products_on_a_manufacturer; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_a_manufacturer ON products USING pgroonga (a_manufacturer);


--
-- Name: index_products_on_a_title; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_a_title ON products USING pgroonga (a_title);


--
-- Name: index_products_on_r_authors; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_r_authors ON products USING pgroonga (r_authors);


--
-- Name: index_products_on_r_manufacturer; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_r_manufacturer ON products USING pgroonga (r_manufacturer);


--
-- Name: index_products_on_r_title; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_r_title ON products USING pgroonga (r_title);


--
-- Name: index_user_products_on_product_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_products_on_product_id ON user_products USING btree (product_id);


--
-- Name: index_user_products_on_tags; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_products_on_tags ON user_products USING gin (tags);


--
-- Name: products_ean; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX products_ean ON products USING btree (ean);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20101124140544');

INSERT INTO schema_migrations (version) VALUES ('20101127044321');

INSERT INTO schema_migrations (version) VALUES ('20101127095956');

INSERT INTO schema_migrations (version) VALUES ('20101127104555');

INSERT INTO schema_migrations (version) VALUES ('20101127125340');

INSERT INTO schema_migrations (version) VALUES ('20101130152024');

INSERT INTO schema_migrations (version) VALUES ('20141220124917');

INSERT INTO schema_migrations (version) VALUES ('20160221090237');

INSERT INTO schema_migrations (version) VALUES ('20160221102853');

INSERT INTO schema_migrations (version) VALUES ('20160221125206');

INSERT INTO schema_migrations (version) VALUES ('20160222104451');

INSERT INTO schema_migrations (version) VALUES ('20160222145543');

INSERT INTO schema_migrations (version) VALUES ('20160223123646');

INSERT INTO schema_migrations (version) VALUES ('20160223143832');

INSERT INTO schema_migrations (version) VALUES ('20160508070550');

INSERT INTO schema_migrations (version) VALUES ('20160508134126');

INSERT INTO schema_migrations (version) VALUES ('20160513130954');

INSERT INTO schema_migrations (version) VALUES ('20160515013022');

