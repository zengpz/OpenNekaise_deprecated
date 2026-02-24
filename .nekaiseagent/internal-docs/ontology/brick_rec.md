Hello, Nekaise Agent.

This document teaches you the Brick ontology. Brick is a uniform metadata schema for buildings. It gives you a shared vocabulary of classes, relationships, and tags to describe everything in a building: equipment, locations, data points, zones, meters, and the connections between them.

You will use Brick to navigate building models expressed as RDF graphs and queried with SPARQL. This document tells you every class hierarchy, every relationship, every namespace, and every query pattern you need. It also tells you how Brick integrates with ASHRAE 223P for connection topology and with QUDT for units of measurement.
Read this before you touch any Brick model.

1. What is Brick
Brick is an open-source effort to standardize semantic descriptions of the physical, logical and virtual assets in buildings and the relationships between them. It consists of three things: an extensible dictionary of terms and concepts (the class hierarchy), a set of relationships for linking entities together, and a flexible data model based on RDF that integrates with existing tools and databases.
Brick uses Semantic Web technology (RDF, OWL, SHACL) so it can describe the broad set of idiosyncratic and custom features found across the building stock in a consistent manner. Brick models are directed, labeled graphs where nodes are entities (equipment, points, locations) and edges are relationships (feeds, hasPoint, hasLocation).
Brick is a concept-first ontology. It models definitions and behavior of concepts
and the relationships between them. This is in contrast to tag-only approaches.
Tags exist in Brick as annotations, but classes carry the formal semantics.
1.1 What Brick Covers
•	HVAC systems: AHUs, VAVs, chillers, boilers, heat exchangers, fans, dampers, valves, coils
•	Lighting systems: luminaires, drivers, switches, dimmers, occupancy sensors
•	Electrical systems: meters, panels, transformers, PV arrays, batteries, inverters
•	Fire safety: smoke detectors, sprinklers, fire alarm panels
•	Security: cameras, access control, intrusion detection
•	Spatial: sites, buildings, floors, rooms, wings, zones (HVAC, lighting, fire)
•	Telemetry: sensors, setpoints, commands, alarms, statuses, parameters

1.2 What Brick Does Not Cover
Brick does not model geometry (3D coordinates, dimensions). For that, use IFC/BIM. Brick does not natively model detailed connection topology (ducts, pipes, wires) — as of Brick 1.4, this is handled by importing ASHRAE 223P connection classes. Brick does not store timeseries data itself; it stores metadata about where timeseries data lives.
2. The Three Root Class Hierarchies
Every entity in a Brick model is an instance of a class under one of three root hierarchies. These are the foundation of everything.
2.1 Equipment
Equipment represents physical mechanical, electrical, and networked devices in a building. Equipment classes are organized in a deep hierarchy. The major branches are:
•	HVAC — AHU, VAV, Chiller, Boiler, Heat_Exchanger, Cooling_Tower, Fan, Damper, Valve, Pump, Compressor, Coil (Heating_Coil, Cooling_Coil), Economizer, Humidifier, Dehumidifier, Filter, Terminal_Unit, FCU, CRAC, CRAH, VRF
•	Lighting — Luminaire, Luminaire_Driver, Lighting_System
•	Electrical — Meter (Electric_Meter, Gas_Meter, Water_Meter, Building_Meter), Inverter, Transformer, Switchgear, Panel, Battery, PV_Panel, PV_Array
•	Networking — Thermostat, Controller, Gateway, Camera, EV_Charger
•	Other — Motor, VFD, Fire_Alarm_Panel, Smoke_Detector, Sprinkler

Equipment can contain other equipment via brick:hasPart. For example, a VAV hasPart a Damper and a Heating_Coil. Equipment can feed other equipment via brick:feeds, indicating upstream/downstream media flow. Equipment can have data points via brick:hasPoint.
2.2 Point
Points are the digital representations of telemetry: sensors, setpoints, commands, alarms, statuses, and parameters. Points are not physical devices — they are virtual entities that represent data streams. The major Point subclasses are:
•	Sensor — Reads the current state of the world. Examples: Air_Temperature_Sensor, Supply_Air_Flow_Sensor, CO2_Sensor, Humidity_Sensor, Power_Sensor, Occupancy_Sensor, Damper_Position_Sensor, Discharge_Air_Temperature_Sensor, Zone_Air_Temperature_Sensor, Outside_Air_Temperature_Sensor
•	Setpoint — A target value for a control loop. Examples: Temperature_Setpoint, Supply_Air_Temperature_Setpoint, Zone_Air_Temperature_Cooling_Setpoint, Pressure_Setpoint, Flow_Setpoint, Humidity_Setpoint
•	Command — A writable value that directly controls equipment behavior. Examples: Damper_Position_Command, Valve_Position_Command, Fan_Speed_Command, On_Off_Command, Cooling_Command, Heating_Command
•	Alarm — A signal alerting to off-normal conditions. Examples: High_Temperature_Alarm, Low_Pressure_Alarm, Filter_Alarm, Fault_Alarm
•	Status — Reports current operational state. Examples: On_Off_Status, Occupancy_Status, Run_Status, Enable_Status, Mode_Status, Fan_Status
•	Parameter — A configurable setting that affects system behavior. Examples: PID_Parameter, Delay_Parameter, Deadband_Parameter, Proportional_Band_Parameter

Naming convention: Brick Point classes follow a systematic pattern.
The class name encodes the substance, quantity, and point type.
Example: Supply_Air_Temperature_Sensor = Supply + Air + Temperature + Sensor.
Use this pattern to find or infer class names programmatically.
2.3 Location
Locations represent spatial elements of the building. The hierarchy includes:
•	Site — A geographic campus or property boundary
•	Building — A structure within a site
•	Wing — A section of a building
•	Floor — A level within a building
•	Room — An enclosed space within a floor
•	Space — A generic spatial area (can be more general than Room)
•	Zone — A logical grouping of spaces: HVAC_Zone, Lighting_Zone, Fire_Zone

Locations can contain other locations via brick:hasPart (a Building hasPart Floors; a Floor hasPart Rooms). Equipment and Points are placed in locations via brick:hasLocation.
3. Relationships (Predicates)
Relationships are the edges of the Brick graph. They define how entities relate to each other across multiple perspectives: composition, topology, telemetry, location, and metering. Every relationship has an inverse.
Relationship	Meaning and Usage
brick:hasPoint	Subject has a telemetry source (Point) identified by object. The Point measures, controls, or monitors some aspect of the subject. Inverse: brick:isPointOf.
brick:hasPart	Subject contains a component identified by object. Used for both physical composition (VAV hasPart Damper) and logical composition (HVAC_Zone hasPart Room). Inverse: brick:isPartOf.
brick:hasLocation	Subject is physically located at the Location identified by object. Not compositional. Inverse: brick:isLocationOf.
brick:feeds	Subject is upstream of object; media flows from subject into object. Used for airflow (AHU feeds VAV), waterflow, and general flow topology. Inverse: brick:isFedBy.
brick:hasUnit	Subject (a Point) has units of measurement given by object (a qudt:Unit instance such as unit:DEG_F or unit:KiloW-HR).
brick:meters	Subject (a Meter) measures the consumption/production of object (an Equipment, Location, or Collection). Inverse: brick:isMeteredBy.
brick:hasSubMeter	Subject (a Meter) has a child meter identified by object. Defines submeter hierarchies. Inverse: brick:isSubMeterOf.
brick:controls	Subject (Equipment) controls object (Equipment). Example: a Controller controls a VAV.
brick:hasTag	Subject has the tag identified by object. Tags are atomic annotations (tag:Air, tag:Temperature, tag:Sensor) used for inference.
brick:measures	Subject (a Point or Equipment) measures the substance or quantity identified by object (brick:Air, brick:Temperature, etc.).
brick:hasInputSubstance	Subject equipment receives the substance as input.
brick:hasOutputSubstance	Subject equipment produces or delivers the substance as output.

Every relationship listed above also has an inverse form (e.g., brick:isPointOf for brick:hasPoint). Both directions are valid in models and queries; Brick tooling supports inference of inverses.
4. Namespace Prefixes
When reading or writing Brick models and SPARQL queries, always use these canonical prefixes:
Prefix	Namespace URI
brick:	https://brickschema.org/schema/Brick#
tag:	https://brickschema.org/schema/BrickTag#
ref:	https://brickschema.org/schema/Brick/ref#
rdf:	http://www.w3.org/1999/02/22-rdf-syntax-ns#
rdfs:	http://www.w3.org/2000/01/rdf-schema#
owl:	http://www.w3.org/2002/07/owl#
qudt:	http://qudt.org/schema/qudt/
unit:	http://qudt.org/vocab/unit/
s223:	http://data.ashrae.org/standard223#
rec:	https://w3id.org/rec#

5. Entity Properties (Static Attributes)
Entity Properties are static attributes of Brick entities whose values change rarely or never. If a value changes regularly, it should be modeled as a Point instead. Entity Properties follow a pattern: the entity links to a blank node that carries a brick:value and optionally a brick:hasUnit.
5.1 Common Entity Properties
•	brick:area — The 2D area of a Location. Value: xsd:decimal, Unit: unit:FT2 or unit:M2
•	brick:volume — The 3D volume of a Location.
•	brick:buildingPrimaryFunction — Primary function of a Building (e.g., "Office", "Manufacturing/Industrial Plant").
•	brick:yearBuilt — Year the building was constructed.
•	brick:isVirtualMeter — Boolean flag on a Meter indicating it is computed rather than physical.
•	brick:aggregate — Aggregation function applied to a Point (e.g., "avg", "sum", "max").

5.2 Entity Property Pattern
@prefix brick: <https://brickschema.org/schema/Brick#> .
@prefix unit: <http://qudt.org/vocab/unit/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix bldg: <urn:example/> .
 
bldg:room1 a brick:Room ;
    brick:area [
        brick:value "100"^^xsd:decimal ;
        brick:hasUnit unit:FT2 ;
    ] .
6. Timeseries and External References
Brick does not store timeseries data. It stores metadata about where timeseries data lives. Each Point can have an external reference linking it to a database, API, or BACnet object. This is how you connect semantic meaning to actual data streams.
6.1 Timeseries Reference Pattern
@prefix brick: <https://brickschema.org/schema/Brick#> .
@prefix ref: <https://brickschema.org/schema/Brick/ref#> .
@prefix unit: <http://qudt.org/vocab/unit/> .
@prefix bldg: <urn:example/> .
 
bldg:temp_sensor_1 a brick:Air_Temperature_Sensor ;
    brick:hasUnit unit:DEG_F ;
    ref:hasExternalReference [
        a ref:TimeseriesReference ;
        ref:hasTimeseriesId "88698ade-9b77-40fa-bbb4-dd9d0adb1f16" ;
        ref:storedAt bldg:timeseries_db ;
    ] .
 
bldg:timeseries_db a ref:Database ;
    ref:connString "postgresql://1.2.3.4:5432/mydata" .
The ref:hasExternalReference property links a Point to a ref:TimeseriesReference that carries a ref:hasTimeseriesId (the primary key in the database) and a ref:storedAt (the database itself). This enables automatic retrieval of data.
7. Collections, Systems, and Loops
A Collection is a named group of related entities, organized around a fixed use or function. The relationship between a collection and its contents is brick:hasPart. Collections enable you to find all entities that belong to a particular system or loop.
•	brick:Collection — Generic named group of entities.
•	brick:HVAC_System — Group of equipment, points and loops that handle HVAC.
•	brick:Lighting_System — Group of lighting equipment.
•	brick:Chilled_Water_System — Equipment and points in the chilled water loop.
•	brick:Hot_Water_System — Equipment and points in the hot water loop.
•	brick:Air_Loop — Equipment and points connected by air flow in a single loop.
•	brick:Water_Loop — Equipment and points connected by water flow.
•	brick:Energy_Generation_System — PV arrays, batteries, inverters, and related equipment.
•	brick:Portfolio — A group of Sites (for multi-site management).

7.1 Collection Example
@prefix brick: <https://brickschema.org/schema/Brick#> .
@prefix : <urn:bldg#> .
 
:hvac_system a brick:HVAC_System .
:air_loop_1 a brick:Air_Loop .
 
:ahu1 a brick:AHU ;
    brick:feeds :vav1, :vav2 ;
    brick:isPartOf :hvac_system, :air_loop_1 .
 
:vav1 a brick:VAV ;
    brick:hasPart :dmp1 ;
    brick:hasPoint :sats1 ;
    brick:feeds :zone1 ;
    brick:isPartOf :hvac_system, :air_loop_1 .
 
:zone1 a brick:HVAC_Zone .
:dmp1 a brick:Damper ; brick:hasPoint :pos1 .
:pos1 a brick:Position_Command .
:sats1 a brick:Supply_Air_Temperature_Sensor .
8. Meters and Submeter Hierarchies
Meters are subclasses of Equipment that measure consumption or production of energy, water, gas, or other substances. Data produced by meters is found in Point instances associated with the Meter via brick:hasPoint.
8.1 Meter Relationships
•	brick:meters / brick:isMeteredBy — Associates a Meter with the entity it measures (Equipment, Location, or Collection).
•	brick:hasSubMeter / brick:isSubMeterOf — Defines submeter hierarchies. A building meter hasSubMeter floor meters.
•	brick:isVirtualMeter — Entity property flagging computed (non-physical) meters.

8.2 Meter Example
@prefix brick: <https://brickschema.org/schema/Brick#> .
@prefix unit: <http://qudt.org/vocab/unit/> .
@prefix bldg: <urn:example/> .
 
bldg:main_meter a brick:Building_Meter ;
    brick:hasSubMeter bldg:floor1_meter, bldg:floor2_meter ;
    brick:meters bldg:building1 .
 
bldg:energy_sensor a brick:Energy_Sensor ;
    brick:hasUnit unit:KiloW-HR ;
    brick:isPointOf bldg:main_meter .
 
bldg:building1 a brick:Building ;
    brick:isMeteredBy bldg:main_meter .
9. Connections via ASHRAE 223P Integration
Brick itself does not model physical connections (ducts, pipes, wires). As of Brick 1.4, connection topology is modeled by importing ASHRAE 223P classes. Brick Equipment classes are now subclasses of s223:Equipment, meaning they can have ConnectionPoints and Connections.
9.1 Key Connection Classes (from 223P)
•	s223:ConnectionPoint — Where equipment connects. Subtypes: InletConnectionPoint, OutletConnectionPoint, BidirectionalConnectionPoint.
•	s223:Connection — The physical conduit. Subtypes: s223:Duct (air), s223:Pipe (water), s223:Wire (electricity).
•	s223:hasMedium — Declares what flows: s223:Fluid-Air, s223:Fluid-Water, s223:Medium-Electricity.
•	s223:cnx — Connects a ConnectionPoint to a Connection or equipment. The foundational topology predicate.
•	s223:hasRole — Role of a ConnectionPoint: s223:Role-Supply, s223:Role-Return, etc.

9.2 Connection Example
@prefix brick: <https://brickschema.org/schema/Brick#> .
@prefix s223: <http://data.ashrae.org/standard223#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix : <urn:example/> .
 
:ahu a brick:AHU ;
    s223:hasConnectionPoint :ahu_air_supply .
 
:ahu_air_supply a s223:OutletConnectionPoint ;
    s223:hasRole s223:Role-Supply ;
    s223:hasMedium s223:Fluid-Air ;
    brick:hasPoint :saf1 .
 
:saf1 a brick:Supply_Air_Flow_Sensor .
 
:vav a brick:VAV ;
    s223:hasConnectionPoint :vav_air_inlet .
 
:vav_air_inlet a s223:InletConnectionPoint ;
    s223:hasMedium s223:Fluid-Air .
 
:duct a s223:Duct ;
    s223:hasMedium s223:Fluid-Air ;
    s223:cnx :ahu_air_supply, :vav_air_inlet .
10. Tags and Inference
Brick classes have associated tags (atomic annotations like tag:Air, tag:Temperature, tag:Sensor). Tags provide a bridge to tag-based systems like Project Haystack. The mapping between tags and classes is bidirectional:
•	Class → Tags: Inference annotates instances of a class with the class's tags. Example: an instance of brick:Air_Temperature_Sensor gets tags tag:Air, tag:Temperature, tag:Sensor, tag:Point.
•	Tags → Class: An entity with all the tags for a class is inferred as an instance of that class. Example: an entity with tag:Air, tag:Temperature, tag:Sensor, tag:Point is inferred as brick:Air_Temperature_Sensor.

Inference also annotates instances with their measured substances and quantities. For example, an instance of brick:Air_Temperature_Sensor gets the inferred relationships brick:measures brick:Air and brick:measures brick:Temperature.
Inference is performed using OWL-RL reasoning (e.g., owlrl library in Python, or SHACL-based tooling). Always apply inference to a Brick model before querying to ensure all implied triples are materialized.
11. Essential SPARQL Query Patterns
These are the query patterns you will use most frequently. Master them.
11.1 Find All Equipment and Their Types
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?equip ?type ?label WHERE {
    ?equip rdf:type/rdfs:subClassOf* brick:Equipment .
    ?equip a ?type .
    OPTIONAL { ?equip rdfs:label ?label }
}
11.2 Find All Points on a Specific Equipment
PREFIX brick: <https://brickschema.org/schema/Brick#>
SELECT ?point ?pointType WHERE {
    <urn:example/ahu1> brick:hasPoint ?point .
    ?point a ?pointType .
    ?pointType rdfs:subClassOf* brick:Point .
}
11.3 Find All Temperature Sensors with Units
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?sensor ?type ?unit ?equip WHERE {
    ?sensor rdf:type/rdfs:subClassOf* brick:Temperature_Sensor .
    ?sensor a ?type .
    OPTIONAL { ?sensor brick:hasUnit ?unit }
    OPTIONAL { ?sensor brick:isPointOf ?equip }
}
11.4 Trace the Feed Chain: AHU → VAV → Zone
PREFIX brick: <https://brickschema.org/schema/Brick#>
SELECT ?ahu ?vav ?zone WHERE {
    ?ahu a brick:AHU ;
         brick:feeds ?vav .
    ?vav a brick:VAV ;
         brick:feeds ?zone .
    ?zone a brick:HVAC_Zone .
}
11.5 Find All Entities in an Air Loop
PREFIX brick: <https://brickschema.org/schema/Brick#>
SELECT ?entity ?type WHERE {
    ?entity brick:isPartOf ?loop .
    ?loop a brick:Air_Loop .
    ?entity a ?type .
}
11.6 Find Timeseries IDs for Points
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX ref: <https://brickschema.org/schema/Brick/ref#>
SELECT ?point ?type ?tsId ?db WHERE {
    ?point rdf:type/rdfs:subClassOf* brick:Point .
    ?point a ?type .
    ?point ref:hasExternalReference ?ref .
    ?ref ref:hasTimeseriesId ?tsId .
    OPTIONAL { ?ref ref:storedAt ?db }
}
11.7 Find Meters and What They Measure
PREFIX brick: <https://brickschema.org/schema/Brick#>
SELECT ?meter ?meterType ?metered ?meteredType WHERE {
    ?meter rdf:type/rdfs:subClassOf* brick:Meter .
    ?meter a ?meterType .
    ?meter brick:meters ?metered .
    ?metered a ?meteredType .
}
11.8 Find Equipment in a Location and Its Points
PREFIX brick: <https://brickschema.org/schema/Brick#>
SELECT ?equip ?equipType ?point ?pointType WHERE {
    ?equip brick:hasLocation <urn:example/floor3> .
    ?equip rdf:type/rdfs:subClassOf* brick:Equipment .
    ?equip a ?equipType .
    ?equip brick:hasPoint ?point .
    ?point a ?pointType .
}
12. Extending Brick
Brick is designed to be extended. If you encounter equipment or point types not in the standard, you can create custom subclasses in your own namespace. Use rdfs:subClassOf to position them in the hierarchy, and owl:equivalentClass to reconcile with future Brick releases.
@prefix brick: <https://brickschema.org/schema/Brick#> .
@prefix ext: <https://example.com/schema/BrickExtension#> .
 
ext:SnowConeMaker rdfs:subClassOf brick:Equipment .
ext:IceMachine rdfs:subClassOf brick:Equipment .
ext:feedsIce rdfs:subPropertyOf brick:feeds .
When official Brick classes later cover the same concept, use owl:equivalentClass to bridge old models to new ones.
13. Python Tooling
The brickschema Python library provides graph loading, inference, querying, and an ORM for working with Brick models programmatically.
from brickschema import Graph
 
g = Graph(load_brick=True)
g.load_file("my_building.ttl")
 
# Apply inference to materialize all implied triples
g.expand(profile="owlrl")
 
# Query for all VAVs and their temperature sensors
results = g.query("""
    PREFIX brick: <https://brickschema.org/schema/Brick#>
    SELECT ?vav ?sensor WHERE {
        ?vav a brick:VAV .
        ?vav brick:hasPoint ?sensor .
        ?sensor a brick:Temperature_Sensor .
    }
""")
The library also supports importing from Haystack JSON exports and serving models via a local SPARQL endpoint.
14. Resources and Access Points
These are your canonical references. Use them.
14.1 Core Documentation
Brick Homepage: https://brickschema.org/ — Overview, links, and getting started
User Documentation: https://docs.brickschema.org — Comprehensive developer docs: concepts, relationships, modeling guides
Ontology Browser: https://ontology.brickschema.org — Interactive exploration of the Brick class hierarchy and constraints
GitHub Repository: https://github.com/BrickSchema/Brick — Source code, releases, issue tracker
14.2 Key Documentation Pages
Core Concepts: https://docs.brickschema.org/brick/concepts.html — Entities, classes, tags, graphs
Relationships: https://docs.brickschema.org/brick/relationships.html — All relationships with definitions and inverse forms
Modeling Data Sources: https://docs.brickschema.org/brick/timeseries.html — Points, units, and data source patterns
Entity Properties: https://docs.brickschema.org/metadata/entity-properties.html — Static attributes: area, volume, year built
Timeseries Storage: https://docs.brickschema.org/metadata/timeseries-storage.html — External references and database linking
Collections & Systems: https://docs.brickschema.org/modeling/collections.html — Systems, loops, and custom collections
Meters: https://docs.brickschema.org/modeling/meters.html — Meter modeling, submeters, virtual meters
Connections (via 223P): https://docs.brickschema.org/modeling/connections.html — Duct/pipe/wire topology using ASHRAE 223P
Extending Brick: https://docs.brickschema.org/extra/extending.html — Custom classes, properties, and reconciliation
14.3 Downloads
Latest Brick Release: https://github.com/BrickSchema/Brick/releases — Turtle files for stable and nightly Brick ontology
Brick Python Library: https://pypi.org/project/brickschema/ — pip install brickschema
Reference Models: https://brickschema.org/resources/ — Example building models in Turtle format
14.4 Related Standards
ASHRAE 223P: https://docs.open223.info/ — Semantic data model for building automation; provides connection topology for Brick 1.4+
QUDT: http://qudt.org/ — Units and quantity kinds ontology used by Brick for measurement semantics
RealEstateCore: https://w3id.org/rec — Space and asset classification ontology; complements Brick space types
Project Haystack: https://project-haystack.org/ — Tag-based building metadata; Brick supports Haystack import/inference
BOT (Building Topology Ontology): https://w3c-lbd-cg.github.io/bot/ — W3C community group ontology for spatial building topology
14.5 Community
Brick User Forum: https://groups.google.com/forum/#!forum/brickschema — Discussion group for Brick users and developers
Brick Consortium: https://brickschema.org/consortium/ — Industry consortium governing Brick development

15. Operational Principles for AI Agents
1.	Load and infer first. Always load the Brick ontology alongside the building model and apply OWL-RL inference before querying. Without inference, you will miss class memberships, tag annotations, and substance/quantity associations.
2.	Navigate the three hierarchies. Every query starts by identifying whether you need Equipment, Point, or Location entities. Use rdf:type/rdfs:subClassOf* to traverse the class hierarchy.
3.	Follow the relationship graph. The path Equipment → hasPoint → Point tells you what data exists. The path Equipment → feeds → Equipment tells you flow topology. The path Equipment → hasLocation → Location tells you where things are.
4.	Use the naming convention. Brick class names encode meaning: Supply_Air_Temperature_Sensor. Parse the name to understand substance (Air), qualifier (Supply), quantity (Temperature), and point type (Sensor).
5.	Check units. Always verify brick:hasUnit on Points before using their values. Never assume units.
6.	Follow timeseries references. Use ref:hasExternalReference to locate actual data. The semantic model tells you what the data means; the external reference tells you where to find it.
7.	Use 223P for topology. If you need to trace physical connections (which duct connects AHU to VAV, which pipe feeds the chiller), use the s223:cnx relations from the 223P integration.
8.	Respect model boundaries. What is not in the model is not known. Do not infer equipment or relationships that are not explicitly stated or inferrable from the ontology rules.

You are working with the ontology that gives building data its meaning.
Without Brick, points are just numbers. With Brick, they are actionable intelligence.
Navigate the graph. Follow the relationships. Connect the meaning to the data.
Be precise. Be accountable. Be useful.
