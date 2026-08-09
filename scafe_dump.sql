--
-- PostgreSQL database dump
--

\restrict Q55FOI4J87ylDuUTXcqpMgSn3TmbMKail8oy5sX3TG0mYjc44ObRL1vvQ52Rswt

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE ONLY scafe_tenant.stock_transactions DROP CONSTRAINT stock_transactions_retail_product_id_fkey;
ALTER TABLE ONLY scafe_tenant.stock_transactions DROP CONSTRAINT stock_transactions_ingredient_id_fkey;
ALTER TABLE ONLY scafe_tenant.stock_transactions DROP CONSTRAINT stock_transactions_created_by_fkey;
ALTER TABLE ONLY scafe_tenant.shifts DROP CONSTRAINT shifts_opened_by_fkey;
ALTER TABLE ONLY scafe_tenant.shifts DROP CONSTRAINT shifts_closed_by_fkey;
ALTER TABLE ONLY scafe_tenant.retail_products DROP CONSTRAINT retail_products_category_id_fkey;
ALTER TABLE ONLY scafe_tenant.recipes DROP CONSTRAINT recipes_menu_item_id_fkey;
ALTER TABLE ONLY scafe_tenant.recipes DROP CONSTRAINT recipes_ingredient_id_fkey;
ALTER TABLE ONLY scafe_tenant.orders DROP CONSTRAINT orders_shift_id_fkey;
ALTER TABLE ONLY scafe_tenant.orders DROP CONSTRAINT orders_created_by_fkey;
ALTER TABLE ONLY scafe_tenant.order_items DROP CONSTRAINT order_items_order_id_fkey;
ALTER TABLE ONLY scafe_tenant.order_items DROP CONSTRAINT order_items_menu_item_id_fkey;
ALTER TABLE ONLY scafe_tenant.menu_items DROP CONSTRAINT menu_items_retail_product_id_fkey;
ALTER TABLE ONLY scafe_tenant.menu_items DROP CONSTRAINT menu_items_parent_id_fkey;
ALTER TABLE ONLY scafe_tenant.menu_items DROP CONSTRAINT menu_items_category_id_fkey;
ALTER TABLE ONLY scafe_tenant.menu_categories DROP CONSTRAINT menu_categories_parent_id_fkey;
ALTER TABLE ONLY scafe_tenant.inventory_documents DROP CONSTRAINT inventory_documents_supplier_id_fkey;
ALTER TABLE ONLY scafe_tenant.inventory_documents DROP CONSTRAINT inventory_documents_created_by_fkey;
ALTER TABLE ONLY scafe_tenant.inventory_document_items DROP CONSTRAINT inventory_document_items_retail_product_id_fkey;
ALTER TABLE ONLY scafe_tenant.inventory_document_items DROP CONSTRAINT inventory_document_items_ingredient_id_fkey;
ALTER TABLE ONLY scafe_tenant.inventory_document_items DROP CONSTRAINT inventory_document_items_document_id_fkey;
ALTER TABLE ONLY scafe_tenant.ingredients DROP CONSTRAINT ingredients_category_id_fkey;
ALTER TABLE ONLY scafe_tenant.cash_transactions DROP CONSTRAINT cash_transactions_user_id_fkey;
ALTER TABLE ONLY scafe_tenant.cash_transactions DROP CONSTRAINT cash_transactions_shift_id_fkey;
DROP INDEX scafe_tenant.ix_suppliers_name;
DROP INDEX scafe_tenant.ix_stock_transactions_retail_product_id;
DROP INDEX scafe_tenant.ix_stock_transactions_ingredient_id;
DROP INDEX scafe_tenant.ix_retail_products_name;
DROP INDEX scafe_tenant.ix_retail_products_category_id;
DROP INDEX scafe_tenant.ix_retail_products_barcode;
DROP INDEX scafe_tenant.ix_recipes_menu_item_id;
DROP INDEX scafe_tenant.ix_recipes_ingredient_id;
DROP INDEX scafe_tenant.ix_orders_shift_id;
DROP INDEX scafe_tenant.ix_order_items_order_id;
DROP INDEX scafe_tenant.ix_menu_items_retail_product_id;
DROP INDEX scafe_tenant.ix_menu_items_parent_id;
DROP INDEX scafe_tenant.ix_menu_items_name;
DROP INDEX scafe_tenant.ix_menu_items_category_id;
DROP INDEX scafe_tenant.ix_menu_items_barcode;
DROP INDEX scafe_tenant.ix_menu_categories_name;
DROP INDEX scafe_tenant.ix_inventory_documents_supplier_id;
DROP INDEX scafe_tenant.ix_inventory_document_items_retail_product_id;
DROP INDEX scafe_tenant.ix_inventory_document_items_ingredient_id;
DROP INDEX scafe_tenant.ix_inventory_document_items_document_id;
DROP INDEX scafe_tenant.ix_ingredients_name;
DROP INDEX scafe_tenant.ix_ingredients_category_id;
DROP INDEX scafe_tenant.ix_ingredients_barcode;
DROP INDEX scafe_tenant.ix_cash_transactions_shift_id;
ALTER TABLE ONLY scafe_tenant.suppliers DROP CONSTRAINT suppliers_pkey;
ALTER TABLE ONLY scafe_tenant.stock_transactions DROP CONSTRAINT stock_transactions_pkey;
ALTER TABLE ONLY scafe_tenant.shifts DROP CONSTRAINT shifts_pkey;
ALTER TABLE ONLY scafe_tenant.retail_products DROP CONSTRAINT retail_products_pkey;
ALTER TABLE ONLY scafe_tenant.recipes DROP CONSTRAINT recipes_pkey;
ALTER TABLE ONLY scafe_tenant.orders DROP CONSTRAINT orders_pkey;
ALTER TABLE ONLY scafe_tenant.order_items DROP CONSTRAINT order_items_pkey;
ALTER TABLE ONLY scafe_tenant.menu_items DROP CONSTRAINT menu_items_pkey;
ALTER TABLE ONLY scafe_tenant.menu_categories DROP CONSTRAINT menu_categories_pkey;
ALTER TABLE ONLY scafe_tenant.inventory_documents DROP CONSTRAINT inventory_documents_pkey;
ALTER TABLE ONLY scafe_tenant.inventory_document_items DROP CONSTRAINT inventory_document_items_pkey;
ALTER TABLE ONLY scafe_tenant.ingredients DROP CONSTRAINT ingredients_pkey;
ALTER TABLE ONLY scafe_tenant.cash_transactions DROP CONSTRAINT cash_transactions_pkey;
ALTER TABLE scafe_tenant.suppliers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.stock_transactions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.shifts ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.retail_products ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.recipes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.orders ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.order_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.menu_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.menu_categories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.inventory_documents ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.inventory_document_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.ingredients ALTER COLUMN id DROP DEFAULT;
ALTER TABLE scafe_tenant.cash_transactions ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE scafe_tenant.suppliers_id_seq;
DROP TABLE scafe_tenant.suppliers;
DROP SEQUENCE scafe_tenant.stock_transactions_id_seq;
DROP TABLE scafe_tenant.stock_transactions;
DROP SEQUENCE scafe_tenant.shifts_id_seq;
DROP TABLE scafe_tenant.shifts;
DROP SEQUENCE scafe_tenant.retail_products_id_seq;
DROP TABLE scafe_tenant.retail_products;
DROP SEQUENCE scafe_tenant.recipes_id_seq;
DROP TABLE scafe_tenant.recipes;
DROP SEQUENCE scafe_tenant.orders_id_seq;
DROP TABLE scafe_tenant.orders;
DROP SEQUENCE scafe_tenant.order_items_id_seq;
DROP TABLE scafe_tenant.order_items;
DROP SEQUENCE scafe_tenant.menu_items_id_seq;
DROP TABLE scafe_tenant.menu_items;
DROP SEQUENCE scafe_tenant.menu_categories_id_seq;
DROP TABLE scafe_tenant.menu_categories;
DROP SEQUENCE scafe_tenant.inventory_documents_id_seq;
DROP TABLE scafe_tenant.inventory_documents;
DROP SEQUENCE scafe_tenant.inventory_document_items_id_seq;
DROP TABLE scafe_tenant.inventory_document_items;
DROP SEQUENCE scafe_tenant.ingredients_id_seq;
DROP TABLE scafe_tenant.ingredients;
DROP SEQUENCE scafe_tenant.cash_transactions_id_seq;
DROP TABLE scafe_tenant.cash_transactions;
DROP TYPE scafe_tenant.unittype;
DROP TYPE scafe_tenant.stocktransactiontype;
DROP TYPE scafe_tenant.paymentmethod;
DROP TYPE scafe_tenant.orderstatus;
DROP TYPE scafe_tenant.cashtransactiontype;
DROP SCHEMA scafe_tenant;
--
-- Name: scafe_tenant; Type: SCHEMA; Schema: -; Owner: mynix
--

CREATE SCHEMA scafe_tenant;


ALTER SCHEMA scafe_tenant OWNER TO mynix;

--
-- Name: cashtransactiontype; Type: TYPE; Schema: scafe_tenant; Owner: mynix
--

CREATE TYPE scafe_tenant.cashtransactiontype AS ENUM (
    'INCOME',
    'EXPENSE',
    'WITHDRAWAL'
);


ALTER TYPE scafe_tenant.cashtransactiontype OWNER TO mynix;

--
-- Name: orderstatus; Type: TYPE; Schema: scafe_tenant; Owner: mynix
--

CREATE TYPE scafe_tenant.orderstatus AS ENUM (
    'NEW',
    'COOKING',
    'READY',
    'COMPLETED',
    'CANCELLED'
);


ALTER TYPE scafe_tenant.orderstatus OWNER TO mynix;

--
-- Name: paymentmethod; Type: TYPE; Schema: scafe_tenant; Owner: mynix
--

CREATE TYPE scafe_tenant.paymentmethod AS ENUM (
    'CASH',
    'CARD',
    'MIXED'
);


ALTER TYPE scafe_tenant.paymentmethod OWNER TO mynix;

--
-- Name: stocktransactiontype; Type: TYPE; Schema: scafe_tenant; Owner: mynix
--

CREATE TYPE scafe_tenant.stocktransactiontype AS ENUM (
    'RECEIPT',
    'WRITE_OFF',
    'AUTO_DEDUCTION',
    'INVENTORY_SURPLUS',
    'INVENTORY_SHORTAGE'
);


ALTER TYPE scafe_tenant.stocktransactiontype OWNER TO mynix;

--
-- Name: unittype; Type: TYPE; Schema: scafe_tenant; Owner: mynix
--

CREATE TYPE scafe_tenant.unittype AS ENUM (
    'KG',
    'G',
    'L',
    'ML',
    'PCS'
);


ALTER TYPE scafe_tenant.unittype OWNER TO mynix;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cash_transactions; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.cash_transactions (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    shift_id integer NOT NULL,
    user_id integer NOT NULL,
    type scafe_tenant.cashtransactiontype NOT NULL,
    amount double precision NOT NULL,
    description character varying(255) NOT NULL
);


ALTER TABLE scafe_tenant.cash_transactions OWNER TO mynix;

--
-- Name: cash_transactions_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.cash_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.cash_transactions_id_seq OWNER TO mynix;

--
-- Name: cash_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.cash_transactions_id_seq OWNED BY scafe_tenant.cash_transactions.id;


--
-- Name: ingredients; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.ingredients (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    unit scafe_tenant.unittype NOT NULL,
    current_stock double precision NOT NULL,
    min_stock_alert double precision NOT NULL,
    cost_per_unit double precision NOT NULL,
    category_id integer,
    sort_order integer NOT NULL,
    attributes jsonb,
    barcode character varying(50)
);


ALTER TABLE scafe_tenant.ingredients OWNER TO mynix;

--
-- Name: ingredients_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.ingredients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.ingredients_id_seq OWNER TO mynix;

--
-- Name: ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.ingredients_id_seq OWNED BY scafe_tenant.ingredients.id;


--
-- Name: inventory_document_items; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.inventory_document_items (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    document_id integer NOT NULL,
    ingredient_id integer,
    retail_product_id integer,
    quantity double precision NOT NULL,
    price_per_unit double precision NOT NULL,
    total_price double precision NOT NULL
);


ALTER TABLE scafe_tenant.inventory_document_items OWNER TO mynix;

--
-- Name: inventory_document_items_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.inventory_document_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.inventory_document_items_id_seq OWNER TO mynix;

--
-- Name: inventory_document_items_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.inventory_document_items_id_seq OWNED BY scafe_tenant.inventory_document_items.id;


--
-- Name: inventory_documents; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.inventory_documents (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    type character varying(9) NOT NULL,
    status character varying(9) DEFAULT 'draft'::character varying NOT NULL,
    date timestamp without time zone NOT NULL,
    supplier_id integer,
    invoice_number character varying(100),
    reason character varying(255),
    total_amount double precision NOT NULL,
    created_by integer
);


ALTER TABLE scafe_tenant.inventory_documents OWNER TO mynix;

--
-- Name: inventory_documents_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.inventory_documents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.inventory_documents_id_seq OWNER TO mynix;

--
-- Name: inventory_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.inventory_documents_id_seq OWNED BY scafe_tenant.inventory_documents.id;


--
-- Name: menu_categories; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.menu_categories (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    category_type character varying(20) NOT NULL,
    sort_order integer NOT NULL,
    color character varying(50),
    icon character varying,
    level integer NOT NULL,
    path character varying(255),
    is_visible boolean NOT NULL,
    parent_id integer
);


ALTER TABLE scafe_tenant.menu_categories OWNER TO mynix;

--
-- Name: menu_categories_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.menu_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.menu_categories_id_seq OWNER TO mynix;

--
-- Name: menu_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.menu_categories_id_seq OWNED BY scafe_tenant.menu_categories.id;


--
-- Name: menu_items; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.menu_items (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    short_name character varying(50),
    tags jsonb,
    category_id integer,
    retail_product_id integer,
    price double precision NOT NULL,
    is_available boolean NOT NULL,
    image_url character varying(500),
    description character varying(500),
    type character varying NOT NULL,
    barcode character varying(50),
    sort_order integer NOT NULL,
    attributes jsonb,
    parent_id integer
);


ALTER TABLE scafe_tenant.menu_items OWNER TO mynix;

--
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.menu_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.menu_items_id_seq OWNER TO mynix;

--
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.menu_items_id_seq OWNED BY scafe_tenant.menu_items.id;


--
-- Name: order_items; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.order_items (
    id integer NOT NULL,
    order_id integer NOT NULL,
    menu_item_id integer NOT NULL,
    menu_item_name character varying(100) NOT NULL,
    quantity integer NOT NULL,
    unit_price double precision NOT NULL,
    unit_cost double precision NOT NULL,
    subtotal double precision NOT NULL,
    item_type character varying NOT NULL,
    selected_options jsonb
);


ALTER TABLE scafe_tenant.order_items OWNER TO mynix;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.order_items_id_seq OWNER TO mynix;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.order_items_id_seq OWNED BY scafe_tenant.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.orders (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    shift_id integer NOT NULL,
    created_by integer NOT NULL,
    order_number integer NOT NULL,
    status scafe_tenant.orderstatus NOT NULL,
    payment_method scafe_tenant.paymentmethod NOT NULL,
    total double precision NOT NULL,
    note character varying(500)
);


ALTER TABLE scafe_tenant.orders OWNER TO mynix;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.orders_id_seq OWNER TO mynix;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.orders_id_seq OWNED BY scafe_tenant.orders.id;


--
-- Name: recipes; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.recipes (
    id integer NOT NULL,
    menu_item_id integer NOT NULL,
    ingredient_id integer NOT NULL,
    quantity_required double precision NOT NULL
);


ALTER TABLE scafe_tenant.recipes OWNER TO mynix;

--
-- Name: recipes_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.recipes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.recipes_id_seq OWNER TO mynix;

--
-- Name: recipes_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.recipes_id_seq OWNED BY scafe_tenant.recipes.id;


--
-- Name: retail_products; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.retail_products (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    category_id integer NOT NULL,
    price double precision NOT NULL,
    cost double precision NOT NULL,
    unit scafe_tenant.unittype NOT NULL,
    current_stock double precision NOT NULL,
    min_stock_alert double precision NOT NULL,
    barcode character varying(50),
    is_available boolean NOT NULL,
    sort_order integer NOT NULL,
    attributes jsonb
);


ALTER TABLE scafe_tenant.retail_products OWNER TO mynix;

--
-- Name: retail_products_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.retail_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.retail_products_id_seq OWNER TO mynix;

--
-- Name: retail_products_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.retail_products_id_seq OWNED BY scafe_tenant.retail_products.id;


--
-- Name: shifts; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.shifts (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    opened_by integer NOT NULL,
    closed_by integer,
    opened_at timestamp without time zone NOT NULL,
    closed_at timestamp without time zone,
    opening_cash double precision NOT NULL,
    closing_cash_expected double precision,
    closing_cash_actual double precision,
    discrepancy double precision,
    is_open boolean NOT NULL
);


ALTER TABLE scafe_tenant.shifts OWNER TO mynix;

--
-- Name: shifts_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.shifts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.shifts_id_seq OWNER TO mynix;

--
-- Name: shifts_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.shifts_id_seq OWNED BY scafe_tenant.shifts.id;


--
-- Name: stock_transactions; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.stock_transactions (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    ingredient_id integer,
    retail_product_id integer,
    type scafe_tenant.stocktransactiontype NOT NULL,
    quantity double precision NOT NULL,
    reason character varying(255) NOT NULL,
    created_by integer
);


ALTER TABLE scafe_tenant.stock_transactions OWNER TO mynix;

--
-- Name: stock_transactions_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.stock_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.stock_transactions_id_seq OWNER TO mynix;

--
-- Name: stock_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.stock_transactions_id_seq OWNED BY scafe_tenant.stock_transactions.id;


--
-- Name: suppliers; Type: TABLE; Schema: scafe_tenant; Owner: mynix
--

CREATE TABLE scafe_tenant.suppliers (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    contact_info character varying(255),
    is_active boolean NOT NULL
);


ALTER TABLE scafe_tenant.suppliers OWNER TO mynix;

--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: scafe_tenant; Owner: mynix
--

CREATE SEQUENCE scafe_tenant.suppliers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE scafe_tenant.suppliers_id_seq OWNER TO mynix;

--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: scafe_tenant; Owner: mynix
--

ALTER SEQUENCE scafe_tenant.suppliers_id_seq OWNED BY scafe_tenant.suppliers.id;


--
-- Name: cash_transactions id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.cash_transactions ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.cash_transactions_id_seq'::regclass);


--
-- Name: ingredients id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.ingredients ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.ingredients_id_seq'::regclass);


--
-- Name: inventory_document_items id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_document_items ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.inventory_document_items_id_seq'::regclass);


--
-- Name: inventory_documents id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_documents ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.inventory_documents_id_seq'::regclass);


--
-- Name: menu_categories id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.menu_categories ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.menu_categories_id_seq'::regclass);


--
-- Name: menu_items id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.menu_items ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.menu_items_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.order_items ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.orders ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.orders_id_seq'::regclass);


--
-- Name: recipes id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.recipes ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.recipes_id_seq'::regclass);


--
-- Name: retail_products id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.retail_products ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.retail_products_id_seq'::regclass);


--
-- Name: shifts id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.shifts ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.shifts_id_seq'::regclass);


--
-- Name: stock_transactions id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.stock_transactions ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.stock_transactions_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.suppliers ALTER COLUMN id SET DEFAULT nextval('scafe_tenant.suppliers_id_seq'::regclass);


--
-- Data for Name: cash_transactions; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.cash_transactions (created_at, updated_at, id, shift_id, user_id, type, amount, description) FROM stdin;
2026-08-06 07:08:26.536162	\N	1	1	72	INCOME	30	Order #1 payment
2026-08-06 07:08:35.287971	\N	2	1	72	INCOME	130	Order #2 payment
2026-08-06 07:08:48.307808	\N	3	1	72	INCOME	45	Order #3 payment
\.


--
-- Data for Name: ingredients; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.ingredients (created_at, updated_at, id, name, unit, current_stock, min_stock_alert, cost_per_unit, category_id, sort_order, attributes, barcode) FROM stdin;
2026-08-06 06:43:25.314544	\N	1	Говяжья котлета	G	5000	1000	0.8	\N	0	{}	\N
2026-08-06 06:43:25.315602	\N	2	Куриное филе	G	3000	800	0.5	\N	0	{}	\N
2026-08-06 06:43:25.316156	\N	3	Булка для бургера	PCS	100	20	15	\N	0	{}	\N
2026-08-06 06:43:25.316156	\N	4	Лаваш тонкий	PCS	50	10	20	\N	0	{}	\N
2026-08-06 06:43:25.316764	\N	5	Салат айсберг	G	2000	500	0.3	\N	0	{}	\N
2026-08-06 06:43:25.317324	\N	6	Помидор	G	3000	500	0.25	\N	0	{}	\N
2026-08-06 06:43:25.317869	\N	7	Огурец маринов.	G	2000	300	0.2	\N	0	{}	\N
2026-08-06 06:43:25.318441	\N	8	Лук репчатый	G	2000	300	0.1	\N	0	{}	\N
2026-08-06 06:43:25.31899	\N	9	Соус фирменный	ML	3000	500	0.15	\N	0	{}	\N
2026-08-06 06:43:25.31899	\N	10	Кетчуп	ML	2000	500	0.1	\N	0	{}	\N
2026-08-06 06:43:25.319582	\N	11	Майонез	ML	2000	500	0.12	\N	0	{}	\N
2026-08-06 06:43:25.320379	\N	12	Картофель фри (заморож.)	G	5000	1000	0.2	\N	0	{}	\N
2026-08-06 06:43:25.320379	\N	13	Масло фритюрное	ML	5000	1000	0.08	\N	0	{}	\N
2026-08-06 06:43:25.320887	\N	14	Кола сироп	ML	5000	1000	0.05	\N	0	{}	\N
2026-08-06 06:43:25.321442	\N	15	Стакан 400мл	PCS	200	50	3	\N	0	{}	\N
2026-08-06 06:43:25.322001	\N	16	Чай пакетированный	PCS	100	20	5	\N	0	{}	\N
2026-08-06 06:43:25.322415	\N	17	Вода кипяток	ML	99999	0	0.001	\N	0	{}	\N
2026-08-06 06:43:25.322804	\N	18	Сыр чеддер	G	2000	500	1.2	\N	0	{}	\N
\.


--
-- Data for Name: inventory_document_items; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.inventory_document_items (created_at, updated_at, id, document_id, ingredient_id, retail_product_id, quantity, price_per_unit, total_price) FROM stdin;
\.


--
-- Data for Name: inventory_documents; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.inventory_documents (created_at, updated_at, id, type, status, date, supplier_id, invoice_number, reason, total_amount, created_by) FROM stdin;
\.


--
-- Data for Name: menu_categories; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.menu_categories (created_at, updated_at, id, name, category_type, sort_order, color, icon, level, path, is_visible, parent_id) FROM stdin;
2026-08-05 16:27:58.046526	\N	12	Шаурма	dish	1	\N	icon:svg:shawarma	1	\N	t	\N
2026-08-05 16:27:58.047067	\N	13	Хотдоги	dish	2	\N	icon:svg:hotdog	1	\N	t	\N
2026-08-05 16:27:58.047067	\N	14	Бургеры	dish	3	\N	icon:svg:burger	1	\N	t	\N
2026-08-05 16:27:58.047067	\N	15	Пицца	dish	4	\N	icon:svg:pizza	1	\N	t	\N
2026-08-05 16:27:58.047067	\N	16	Гарниры	dish	5	\N	icon:svg:side_dish	1	\N	t	\N
2026-08-05 16:27:58.047067	\N	17	Соусы	dish	6	\N	icon:svg:sauces	1	\N	t	\N
2026-08-05 16:27:58.047067	\N	18	Мороженое	dish	7	\N	icon:svg:ice_cream	1	\N	t	\N
2026-08-06 07:39:04.556941	\N	44	Напитки	retail	1	\N	icon:svg:drinks	1	\N	t	\N
2026-08-06 07:40:40.610309	\N	45	Газировки	retail	1	\N	\N	1	\N	t	44
2026-08-06 07:40:40.610309	\N	46	Вода	retail	2	\N	\N	1	\N	t	44
2026-08-06 07:40:40.610309	\N	47	Чаи	retail	3	\N	\N	1	\N	t	44
2026-08-06 07:40:40.610309	\N	48	Соки	retail	4	\N	\N	1	\N	t	44
2026-08-06 07:40:40.610886	\N	49	Энергетики	retail	5	\N	\N	1	\N	t	44
\.


--
-- Data for Name: menu_items; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.menu_items (created_at, updated_at, id, name, short_name, tags, category_id, retail_product_id, price, is_available, image_url, description, type, barcode, sort_order, attributes, parent_id) FROM stdin;
2026-08-05 16:32:28.264817	\N	2	Шурма в пыте	\N	null	12	\N	10	t	\N	\N	dish	\N	0	{"variations": [{"name": "S", "price": 10}, {"name": "M", "price": 15}]}	\N
2026-08-06 07:33:28.735472	\N	68	Кетчуп	\N	null	17	\N	5	t	\N	\N	dish	\N	1	null	\N
2026-08-05 16:32:28.273076	2026-08-05 16:33:04.399767	3	Шаурма курыная	\N	null	12	\N	15	t	\N	\N	dish	\N	1	{"variations": [{"name": "S", "price": 15}, {"name": "M", "price": 20}, {"name": "L", "price": 25}]}	\N
2026-08-05 16:36:27.775429	\N	5	Классический хотдог	\N	null	13	\N	5	t	\N	\N	dish	\N	0	{"variations": [{"name": "S", "price": 5}, {"name": "M", "price": 7}, {"name": "L", "price": 10}, {"name": "XL", "price": 12}, {"name": "2XL", "price": 15}]}	\N
2026-08-05 16:36:27.796766	\N	6	Булочка	\N	null	13	\N	6	t	\N	\N	dish	\N	2	{"variations": [{"name": "S", "price": 6}, {"name": "M", "price": 8}, {"name": "L", "price": 10}, {"name": "XL", "price": 12}, {"name": "2XL", "price": 15}]}	\N
2026-08-05 16:36:27.800037	\N	7	Нон кабоб	\N	null	13	\N	12	t	\N	\N	dish	\N	3	null	\N
2026-08-05 16:36:27.801662	\N	8	Хотдог S	\N	null	13	\N	15	t	\N	\N	dish	\N	1	null	\N
2026-08-05 16:32:28.35105	2026-08-05 16:37:21.195431	4	Шаурма говяжая	\N	null	12	\N	30	t	\N	\N	dish	\N	2	{}	\N
2026-08-06 07:02:45.474399	\N	43	Дабл Бургер	\N	null	14	\N	37	t	\N	\N	dish	\N	0	null	\N
2026-08-06 07:02:45.712693	\N	44	Бургер по мексиканский	\N	null	14	\N	30	t	\N	\N	dish	\N	2	null	\N
2026-08-06 07:02:45.728779	\N	45	Бест Бургер	\N	null	14	\N	28	t	\N	\N	dish	\N	1	null	\N
2026-08-06 07:02:45.798515	\N	46	Бургер Классический	\N	null	14	\N	30	t	\N	\N	dish	\N	3	null	\N
2026-08-06 07:02:45.811368	\N	47	Чикен Бургер	\N	null	14	\N	20	t	\N	\N	dish	\N	5	null	\N
2026-08-06 07:02:45.925213	\N	49	Бургер SCafe	\N	null	14	\N	49	t	\N	\N	dish	\N	6	null	\N
2026-08-06 07:02:45.916136	\N	48	Бургер Гота	\N	null	14	\N	25	t	\N	\N	dish	\N	4	null	\N
2026-08-06 07:08:01.259038	\N	50	Мясной	\N	null	15	\N	71	t	\N	\N	dish	\N	1	null	\N
2026-08-06 07:08:01.26458	\N	51	Маргарита	\N	null	15	\N	59	t	\N	\N	dish	\N	0	null	\N
2026-08-06 07:08:01.26744	\N	52	Пеперони	\N	null	15	\N	63	t	\N	\N	dish	\N	3	null	\N
2026-08-06 07:08:01.270638	\N	53	Цезарь	\N	null	15	\N	65	t	\N	\N	dish	\N	2	null	\N
2026-08-06 07:08:01.355742	\N	54	Двойной пеперони	\N	null	15	\N	75	t	\N	\N	dish	\N	4	null	\N
2026-08-06 07:08:01.62019	\N	55	Барбекю	\N	null	15	\N	73	t	\N	\N	dish	\N	5	null	\N
2026-08-06 07:08:01.693827	\N	56	Пицца SCafe	\N	null	15	\N	81	t	\N	\N	dish	\N	9	null	\N
2026-08-06 07:08:01.695959	\N	57	Асарти	\N	null	15	\N	70	t	\N	\N	dish	\N	6	null	\N
2026-08-06 07:08:01.70948	\N	58	4 Сезой	\N	null	15	\N	78	t	\N	\N	dish	\N	8	null	\N
2026-08-06 07:08:01.760667	\N	59	Пицца куринная	\N	null	15	\N	61	t	\N	\N	dish	\N	10	null	\N
2026-08-06 07:08:01.788724	\N	60	4 Сыра	\N	null	15	\N	72	t	\N	\N	dish	\N	7	null	\N
2026-08-06 07:08:01.85821	\N	61	Пицца с грыбами	\N	null	15	\N	66	t	\N	\N	dish	\N	11	null	\N
2026-08-06 07:32:07.788239	\N	63	Фри	\N	null	16	\N	11	t	\N	\N	dish	\N	0	{"variations": [{"name": "S", "price": 11}, {"name": "M", "price": 20}]}	\N
2026-08-06 07:32:07.784608	\N	64	Фри шарик	\N	null	16	\N	14	t	\N	\N	dish	\N	2	{"variations": [{"name": "S", "price": 14}, {"name": "M", "price": 22}]}	\N
2026-08-06 07:32:07.80976	\N	65	Нагетси	\N	null	16	\N	18	t	\N	\N	dish	\N	4	{"variations": [{"name": "S", "price": 18}, {"name": "M", "price": 35}]}	\N
2026-08-06 07:32:07.832743	\N	66	Чикен фри	\N	null	16	\N	35	t	\N	\N	dish	\N	3	null	\N
2026-08-06 07:32:07.856007	\N	67	Крилышки	\N	null	16	\N	24	t	\N	\N	dish	\N	5	null	\N
2026-08-06 07:32:07.734426	2026-08-06 07:32:35.786377	62	Картошка по деревенский	\N	null	16	\N	10	t	\N	\N	dish	\N	1	null	\N
2026-08-06 07:33:28.7366	\N	69	Сырный	\N	null	17	\N	5	t	\N	\N	dish	\N	0	null	\N
2026-08-06 07:33:28.761583	\N	70	Чесночный	\N	null	17	\N	5	t	\N	\N	dish	\N	2	null	\N
2026-08-06 07:35:16.281159	\N	71	В рожке	\N	null	18	\N	2	t	\N	\N	dish	\N	0	{"variations": [{"name": "S", "price": 2}, {"name": "M", "price": 3}, {"name": "L", "price": 5}]}	\N
2026-08-06 07:35:16.287257	\N	72	В стаканчике	\N	null	18	\N	5	t	\N	\N	dish	\N	1	{"variations": [{"name": "S", "price": 5}, {"name": "M", "price": 10}]}	\N
2026-08-06 08:05:39.548978	\N	73	Coca-Cola	\N	null	45	\N	10	t	\N	\N	retail	\N	0	{"icon": "package", "flavor": "Классик", "variations": [{"name": "Coca-Cola Классик 0.5 л", "unit": "l", "price": 10, "stock": 12, "barcode": null, "purchasePrice": 5}, {"name": "Coca-Cola Классик 1 л", "unit": "l", "price": 15, "stock": 10, "barcode": null, "purchasePrice": 10}, {"name": "Coca-Cola Классик 1.5 л", "unit": "l", "price": 20, "stock": 5, "barcode": null, "purchasePrice": 15}]}	\N
2026-08-06 08:05:39.550688	\N	74	Coca-Cola	\N	null	45	\N	10	t	\N	\N	retail	\N	0	{"icon": "package", "flavor": "Зеро", "variations": [{"name": "Coca-Cola Зеро 0.5 л", "unit": "l", "price": 10, "stock": 12, "barcode": null, "purchasePrice": 5}, {"name": "Coca-Cola Зеро 1 л", "unit": "l", "price": 15, "stock": 10, "barcode": null, "purchasePrice": 10}, {"name": "Coca-Cola Зеро 1.5 л", "unit": "l", "price": 20, "stock": 5, "barcode": null, "purchasePrice": 15}]}	\N
2026-08-06 08:05:39.741782	\N	75	Coca-Cola Зеро 0.5 л	\N	[]	45	4	10	t	\N	\N	retail	\N	0	null	74
2026-08-06 08:05:39.743598	\N	76	Coca-Cola Классик 0.5 л	\N	[]	45	5	10	t	\N	\N	retail	\N	0	null	73
2026-08-06 08:05:39.802253	\N	77	Coca-Cola Зеро 1 л	\N	[]	45	6	15	t	\N	\N	retail	\N	0	null	74
2026-08-06 08:05:39.85642	\N	78	Coca-Cola Зеро 1.5 л	\N	[]	45	8	20	t	\N	\N	retail	\N	0	null	74
2026-08-06 08:05:39.860772	\N	79	Coca-Cola Классик 1 л	\N	[]	45	7	15	t	\N	\N	retail	\N	0	null	73
2026-08-06 08:05:40.146855	\N	80	Coca-Cola Классик 1.5 л	\N	[]	45	9	20	t	\N	\N	retail	\N	0	null	73
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.order_items (id, order_id, menu_item_id, menu_item_name, quantity, unit_price, unit_cost, subtotal, item_type, selected_options) FROM stdin;
1	1	4	Шаурма говяжая	1	30	0	30	dish	{}
2	2	51	Маргарита	1	59	0	59	dish	{}
3	2	50	Мясной	1	71	0	71	dish	{}
4	3	3	Шаурма курыная	1	20	0	20	dish	{"variation": "M"}
5	3	3	Шаурма курыная	1	25	0	25	dish	{"variation": "L"}
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.orders (created_at, updated_at, id, shift_id, created_by, order_number, status, payment_method, total, note) FROM stdin;
2026-08-06 07:08:26.486103	2026-08-06 07:09:10.289643	1	1	72	1	READY	CASH	30	\N
2026-08-06 07:08:48.274285	2026-08-06 07:09:11.38372	3	1	72	3	READY	CASH	45	\N
2026-08-06 07:08:35.171311	2026-08-06 07:09:12.124614	2	1	72	2	READY	CASH	130	\N
\.


--
-- Data for Name: recipes; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.recipes (id, menu_item_id, ingredient_id, quantity_required) FROM stdin;
\.


--
-- Data for Name: retail_products; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.retail_products (created_at, updated_at, id, name, category_id, price, cost, unit, current_stock, min_stock_alert, barcode, is_available, sort_order, attributes) FROM stdin;
2026-08-06 08:05:39.67768	\N	4	Coca-Cola Зеро 0.5 л	45	10	5	L	12	0	\N	t	0	null
2026-08-06 08:05:39.675021	\N	5	Coca-Cola Классик 0.5 л	45	10	5	L	12	0	\N	t	0	null
2026-08-06 08:05:39.7932	\N	6	Coca-Cola Зеро 1 л	45	15	10	L	10	0	\N	t	0	null
2026-08-06 08:05:39.794845	\N	7	Coca-Cola Классик 1 л	45	15	10	L	10	0	\N	t	0	null
2026-08-06 08:05:39.847518	\N	8	Coca-Cola Зеро 1.5 л	45	20	15	L	5	0	\N	t	0	null
2026-08-06 08:05:40.131157	\N	9	Coca-Cola Классик 1.5 л	45	20	15	L	5	0	\N	t	0	null
\.


--
-- Data for Name: shifts; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.shifts (created_at, updated_at, id, opened_by, closed_by, opened_at, closed_at, opening_cash, closing_cash_expected, closing_cash_actual, discrepancy, is_open) FROM stdin;
2026-08-05 16:06:33.052	\N	1	72	\N	2026-08-05 16:06:33.052	\N	500	\N	\N	\N	t
\.


--
-- Data for Name: stock_transactions; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.stock_transactions (created_at, updated_at, id, ingredient_id, retail_product_id, type, quantity, reason, created_by) FROM stdin;
2026-08-06 08:05:39.716436	\N	4	\N	4	RECEIPT	12	Начальный остаток при создании	1
2026-08-06 08:05:39.719433	\N	5	\N	5	RECEIPT	12	Начальный остаток при создании	1
2026-08-06 08:05:39.798431	\N	6	\N	6	RECEIPT	10	Начальный остаток при создании	1
2026-08-06 08:05:39.851968	\N	7	\N	8	RECEIPT	5	Начальный остаток при создании	1
2026-08-06 08:05:39.837023	\N	8	\N	7	RECEIPT	10	Начальный остаток при создании	1
2026-08-06 08:05:40.138397	\N	9	\N	9	RECEIPT	5	Начальный остаток при создании	1
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: scafe_tenant; Owner: mynix
--

COPY scafe_tenant.suppliers (created_at, updated_at, id, name, contact_info, is_active) FROM stdin;
\.


--
-- Name: cash_transactions_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.cash_transactions_id_seq', 3, true);


--
-- Name: ingredients_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.ingredients_id_seq', 18, true);


--
-- Name: inventory_document_items_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.inventory_document_items_id_seq', 1, false);


--
-- Name: inventory_documents_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.inventory_documents_id_seq', 1, false);


--
-- Name: menu_categories_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.menu_categories_id_seq', 49, true);


--
-- Name: menu_items_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.menu_items_id_seq', 105, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.order_items_id_seq', 5, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.orders_id_seq', 3, true);


--
-- Name: recipes_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.recipes_id_seq', 23, true);


--
-- Name: retail_products_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.retail_products_id_seq', 36, true);


--
-- Name: shifts_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.shifts_id_seq', 1, true);


--
-- Name: stock_transactions_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.stock_transactions_id_seq', 36, true);


--
-- Name: suppliers_id_seq; Type: SEQUENCE SET; Schema: scafe_tenant; Owner: mynix
--

SELECT pg_catalog.setval('scafe_tenant.suppliers_id_seq', 1, false);


--
-- Name: cash_transactions cash_transactions_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.cash_transactions
    ADD CONSTRAINT cash_transactions_pkey PRIMARY KEY (id);


--
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);


--
-- Name: inventory_document_items inventory_document_items_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_document_items
    ADD CONSTRAINT inventory_document_items_pkey PRIMARY KEY (id);


--
-- Name: inventory_documents inventory_documents_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_documents
    ADD CONSTRAINT inventory_documents_pkey PRIMARY KEY (id);


--
-- Name: menu_categories menu_categories_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.menu_categories
    ADD CONSTRAINT menu_categories_pkey PRIMARY KEY (id);


--
-- Name: menu_items menu_items_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);


--
-- Name: retail_products retail_products_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.retail_products
    ADD CONSTRAINT retail_products_pkey PRIMARY KEY (id);


--
-- Name: shifts shifts_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (id);


--
-- Name: stock_transactions stock_transactions_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.stock_transactions
    ADD CONSTRAINT stock_transactions_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: ix_cash_transactions_shift_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_cash_transactions_shift_id ON scafe_tenant.cash_transactions USING btree (shift_id);


--
-- Name: ix_ingredients_barcode; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_ingredients_barcode ON scafe_tenant.ingredients USING btree (barcode);


--
-- Name: ix_ingredients_category_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_ingredients_category_id ON scafe_tenant.ingredients USING btree (category_id);


--
-- Name: ix_ingredients_name; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_ingredients_name ON scafe_tenant.ingredients USING btree (name);


--
-- Name: ix_inventory_document_items_document_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_inventory_document_items_document_id ON scafe_tenant.inventory_document_items USING btree (document_id);


--
-- Name: ix_inventory_document_items_ingredient_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_inventory_document_items_ingredient_id ON scafe_tenant.inventory_document_items USING btree (ingredient_id);


--
-- Name: ix_inventory_document_items_retail_product_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_inventory_document_items_retail_product_id ON scafe_tenant.inventory_document_items USING btree (retail_product_id);


--
-- Name: ix_inventory_documents_supplier_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_inventory_documents_supplier_id ON scafe_tenant.inventory_documents USING btree (supplier_id);


--
-- Name: ix_menu_categories_name; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_menu_categories_name ON scafe_tenant.menu_categories USING btree (name);


--
-- Name: ix_menu_items_barcode; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_menu_items_barcode ON scafe_tenant.menu_items USING btree (barcode);


--
-- Name: ix_menu_items_category_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_menu_items_category_id ON scafe_tenant.menu_items USING btree (category_id);


--
-- Name: ix_menu_items_name; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_menu_items_name ON scafe_tenant.menu_items USING btree (name);


--
-- Name: ix_menu_items_parent_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_menu_items_parent_id ON scafe_tenant.menu_items USING btree (parent_id);


--
-- Name: ix_menu_items_retail_product_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_menu_items_retail_product_id ON scafe_tenant.menu_items USING btree (retail_product_id);


--
-- Name: ix_order_items_order_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_order_items_order_id ON scafe_tenant.order_items USING btree (order_id);


--
-- Name: ix_orders_shift_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_orders_shift_id ON scafe_tenant.orders USING btree (shift_id);


--
-- Name: ix_recipes_ingredient_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_recipes_ingredient_id ON scafe_tenant.recipes USING btree (ingredient_id);


--
-- Name: ix_recipes_menu_item_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_recipes_menu_item_id ON scafe_tenant.recipes USING btree (menu_item_id);


--
-- Name: ix_retail_products_barcode; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_retail_products_barcode ON scafe_tenant.retail_products USING btree (barcode);


--
-- Name: ix_retail_products_category_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_retail_products_category_id ON scafe_tenant.retail_products USING btree (category_id);


--
-- Name: ix_retail_products_name; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_retail_products_name ON scafe_tenant.retail_products USING btree (name);


--
-- Name: ix_stock_transactions_ingredient_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_stock_transactions_ingredient_id ON scafe_tenant.stock_transactions USING btree (ingredient_id);


--
-- Name: ix_stock_transactions_retail_product_id; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_stock_transactions_retail_product_id ON scafe_tenant.stock_transactions USING btree (retail_product_id);


--
-- Name: ix_suppliers_name; Type: INDEX; Schema: scafe_tenant; Owner: mynix
--

CREATE INDEX ix_suppliers_name ON scafe_tenant.suppliers USING btree (name);


--
-- Name: cash_transactions cash_transactions_shift_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.cash_transactions
    ADD CONSTRAINT cash_transactions_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES scafe_tenant.shifts(id);


--
-- Name: cash_transactions cash_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.cash_transactions
    ADD CONSTRAINT cash_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: ingredients ingredients_category_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.ingredients
    ADD CONSTRAINT ingredients_category_id_fkey FOREIGN KEY (category_id) REFERENCES scafe_tenant.menu_categories(id);


--
-- Name: inventory_document_items inventory_document_items_document_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_document_items
    ADD CONSTRAINT inventory_document_items_document_id_fkey FOREIGN KEY (document_id) REFERENCES scafe_tenant.inventory_documents(id);


--
-- Name: inventory_document_items inventory_document_items_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_document_items
    ADD CONSTRAINT inventory_document_items_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES scafe_tenant.ingredients(id);


--
-- Name: inventory_document_items inventory_document_items_retail_product_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_document_items
    ADD CONSTRAINT inventory_document_items_retail_product_id_fkey FOREIGN KEY (retail_product_id) REFERENCES scafe_tenant.retail_products(id);


--
-- Name: inventory_documents inventory_documents_created_by_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_documents
    ADD CONSTRAINT inventory_documents_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: inventory_documents inventory_documents_supplier_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.inventory_documents
    ADD CONSTRAINT inventory_documents_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES scafe_tenant.suppliers(id);


--
-- Name: menu_categories menu_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.menu_categories
    ADD CONSTRAINT menu_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES scafe_tenant.menu_categories(id);


--
-- Name: menu_items menu_items_category_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.menu_items
    ADD CONSTRAINT menu_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES scafe_tenant.menu_categories(id);


--
-- Name: menu_items menu_items_parent_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.menu_items
    ADD CONSTRAINT menu_items_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES scafe_tenant.menu_items(id);


--
-- Name: menu_items menu_items_retail_product_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.menu_items
    ADD CONSTRAINT menu_items_retail_product_id_fkey FOREIGN KEY (retail_product_id) REFERENCES scafe_tenant.retail_products(id);


--
-- Name: order_items order_items_menu_item_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.order_items
    ADD CONSTRAINT order_items_menu_item_id_fkey FOREIGN KEY (menu_item_id) REFERENCES scafe_tenant.menu_items(id);


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES scafe_tenant.orders(id);


--
-- Name: orders orders_created_by_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.orders
    ADD CONSTRAINT orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: orders orders_shift_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.orders
    ADD CONSTRAINT orders_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES scafe_tenant.shifts(id);


--
-- Name: recipes recipes_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.recipes
    ADD CONSTRAINT recipes_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES scafe_tenant.ingredients(id);


--
-- Name: recipes recipes_menu_item_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.recipes
    ADD CONSTRAINT recipes_menu_item_id_fkey FOREIGN KEY (menu_item_id) REFERENCES scafe_tenant.menu_items(id);


--
-- Name: retail_products retail_products_category_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.retail_products
    ADD CONSTRAINT retail_products_category_id_fkey FOREIGN KEY (category_id) REFERENCES scafe_tenant.menu_categories(id);


--
-- Name: shifts shifts_closed_by_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.shifts
    ADD CONSTRAINT shifts_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES public.users(id);


--
-- Name: shifts shifts_opened_by_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.shifts
    ADD CONSTRAINT shifts_opened_by_fkey FOREIGN KEY (opened_by) REFERENCES public.users(id);


--
-- Name: stock_transactions stock_transactions_created_by_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.stock_transactions
    ADD CONSTRAINT stock_transactions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: stock_transactions stock_transactions_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.stock_transactions
    ADD CONSTRAINT stock_transactions_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES scafe_tenant.ingredients(id);


--
-- Name: stock_transactions stock_transactions_retail_product_id_fkey; Type: FK CONSTRAINT; Schema: scafe_tenant; Owner: mynix
--

ALTER TABLE ONLY scafe_tenant.stock_transactions
    ADD CONSTRAINT stock_transactions_retail_product_id_fkey FOREIGN KEY (retail_product_id) REFERENCES scafe_tenant.retail_products(id);


--
-- PostgreSQL database dump complete
--

\unrestrict Q55FOI4J87ylDuUTXcqpMgSn3TmbMKail8oy5sX3TG0mYjc44ObRL1vvQ52Rswt

