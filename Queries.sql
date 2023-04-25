/******** Commonly Used Queries on my last job ***********/

/* Analyze the processing size of queries */
SELECT
  query,
  COUNT(query),
  SUM(CAST(total_bytes_processed / 1000000000000 AS numeric)) AS tb,
FROM
  `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE
  project_id = 'example.'
GROUP BY
  query
ORDER BY
  tb DESC;

------------------------------------------------
/* Analyze the results of an A/B experiment */

SELECT
  "Cards Home - Android" AS experimentName,
  CASE userProperty.value.string_value
    WHEN "0" THEN "Reference Value"
    WHEN "1" THEN "Variant A"
    WHEN "2" THEN "Variant B"
END
  AS experimentVariant,
  h.value.string_value AS event_name,
  COUNT(*) AS count
FROM
  `example.`,
  UNNEST(user_properties) AS userProperty,
  UNNEST(event_params) AS h
WHERE
  (_TABLE_SUFFIX BETWEEN '20230310'
    AND '20230612')
  AND userProperty.key = "firebase_exp_32"
  AND event_name IN ("event_example")
  AND h.key = "param_example"
GROUP BY
  experimentVariant,
  event_name
ORDER BY
  experimentVariant,
  event_name
  
------------------------------------------------
/* Analyze the origin of the web traffic */

SELECT 
  DATE(TIMESTAMP_MICROS(event_timestamp),"America/Belem") AS dateRegister,
  user_pseudo_id AS uid,
    (SELECT value.string_value FROM UNNEST(event_params) 
      WHERE key = "campaign") AS campaign,
    (SELECT value.string_value FROM UNNEST(event_params) 
      WHERE key = "medium") AS meal_type,
    (SELECT value.string_value FROM UNNEST(event_params) 
      WHERE key = "source") AS sources,
    (SELECT value.string_value FROM UNNEST(event_params) 
      WHERE key = "term") AS food_profile_id,
    (SELECT value.string_value FROM UNNEST(event_params) 
      WHERE key = "page_title") AS page_title,
    (SELECT value.string_value FROM UNNEST(event_params) 
      WHERE key = "page_location") AS page_location,
  FROM `example.`
WHERE event_name = "web_recipe_view"

------------------------------------------------
/* Get results for page view outside Brazil and in a translated recipe */

SELECT
  COUNT(DISTINCT user_pseudo_id) AS userCount,
  (
  SELECT
    value.string_value
  FROM
    UNNEST(event_params)
  WHERE
    KEY = "page_title") AS page_title,
  (
  SELECT
    CASE
      WHEN REGEXP_CONTAINS (value.string_value,r'recipes') THEN "en"
      WHEN REGEXP_CONTAINS (value.string_value,r'receitas') THEN "pt"
      WHEN REGEXP_CONTAINS (value.string_value,r'recettes') THEN "fr"
      WHEN REGEXP_CONTAINS (value.string_value,r'recetas') THEN "es"
      WHEN REGEXP_CONTAINS (value.string_value,r'rezepte') THEN "de"
      WHEN REGEXP_CONTAINS (value.string_value,r'ricette') THEN "it"
  END
    AS languange,
  FROM
    UNNEST(event_params)
  WHERE
    KEY = "page_location") AS languange,
FROM
  `example.`
WHERE
  event_name = "web_recipe_view"
  AND _TABLE_SUFFIX > '20221116'
  AND device.operating_system NOT IN ("pt-br",
    "pt-pt")
  AND geo.country NOT IN ("Brazil")
  AND DATE(TIMESTAMP_MICROS(event_timestamp),"America/Belem") > "2022-11-20"
GROUP BY
  languange,
  page_title
