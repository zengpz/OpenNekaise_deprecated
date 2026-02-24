
Semantic building data using the 223P ontology and related standards.

Hello, Nekaise Agent.

1. What is ASHRAE Standard 223P
ASHRAE Standard 223P is a proposed standard titled Semantic Data Model for Analytics and Automation Applications in Buildings. Its formal purpose is to define knowledge concepts and a methodology for creating interoperable, machine-readable semantic frameworks that represent building automation and control data.
In plain terms: 223P gives you a shared vocabulary and a set of structural rules for describing what is inside a building, how those things connect, and what they measure or control. It is expressed in RDF using SHACL shapes and is designed to be queried with SPARQL.
Think of 223P as the grammar of building intelligence.
It does not contain telemetry data itself. It tells you what the data means,
where to find it, and how the systems producing it are connected.
1.1 Scope
The standard covers building automation systems including HVAC, lighting, electrical, plumbing, and related domains. It models topology (how equipment and spaces connect and how media flows between them) but not geometry (physical dimensions or coordinates). The scope includes equipment, sensors, actuators, controllers, connection points, ducts, pipes, wires, zones, physical spaces, and the properties those entities expose.
1.2 Relationship to Other Ontologies
223P is designed to work alongside, not replace, other ontologies. The Brick Schema and RealEstateCore can serve as additional layers on top of 223P, providing richer vocabularies for equipment types and space classifications. QUDT (Quantities, Units, Dimensions and Types) is used within 223P to represent units of measurement and quantity kinds. A building modeled with 223P can simultaneously carry Brick annotations, RealEstateCore space types, and QUDT unit definitions.
2. Core Concepts and Classes
Every entity in a 223P model is an instance of a class defined by the standard. The major classes are described below. As an AI agent, you need to understand these to correctly interpret any 223P graph.
2.1 Connectables
A Connectable is the top-level entity that can participate in connections. There are three major sub-classes:
•	Equipment — Mechanical devices such as pumps, fans, heat exchangers, dampers, luminaires, sensors, and flow meters. Equipment may contain other equipment (e.g., a VAV containing a damper and a reheat coil). Sensors, Actuators, and Controllers are special subclasses of Equipment that have unique relationships to Properties.
•	DomainSpace — A portion of a PhysicalSpace associated with a building service domain (e.g., HVAC, lighting). A DomainSpace is often served by a specific piece of equipment. Multiple DomainSpaces controlled similarly can be grouped into a Zone.
•	Junction — A modeling construct representing important branching points within a Connection (e.g., where a duct splits into two branches).
2.2 Connections and ConnectionPoints
Connections represent the physical things through which a medium is conveyed: ducts, pipes, wires. ConnectionPoints model where a Connectable attaches to a Connection. They have direction: InletConnectionPoint, OutletConnectionPoint, or BidirectionalConnectionPoint. Each ConnectionPoint declares the Medium it carries.
2.3 Mediums
Mediums describe what flows through connections. They are defined as EnumerationKinds in the standard. Examples include Fluid-Air, Fluid-Water, Medium-Electricity. Every ConnectionPoint and Connection declares its Medium so that you know what is being conveyed.
2.4 Properties
Properties are representations of some quality or characteristic of the building that may be observable, quantifiable, or actuatable. In 223P, a Property is associated with a single sensor or actuator. Think of Properties as the source of the measurement or value that eventually becomes exposed in the building management system as a point.
There are multiple types of Properties:
•	ObservableProperty — sensor readings (what is observed)
•	ActuatableProperty — control points that can be written to
•	QuantifiableProperty — numeric values with units and quantity kinds (via QUDT)
•	EnumerableProperty — non-numeric values with enumerated kinds (e.g., on/off, alarm states)
Properties also have Aspects that establish context. For example, if a Property has a Temperature value of 80.6, aspects are used to state what that represents (e.g., a temperature limit during working hours, or a supply temperature setpoint). A Property may have an external reference indicating where the live data can be found, commonly a BACnet object.
Critical distinction: 223P does not contain real-time telemetry.
It provides the meaning and context of data points and can link to their sources.
Your job is to use the semantic model to find, interpret, and connect the right data.
2.5 Sensors, Actuators, and Functions
A Sensor is constrained to observe a single ObservableProperty. Equipment that observes multiple kinds of properties (e.g., temperature and humidity) is modeled as an Equipment instance that contains individual sensor subclasses. An Actuator is associated with an ActuatableProperty via the actuatedByProperty relation.
FunctionBlocks represent mathematical or logical operations. A Function has input properties (hasInput) and output properties (hasOutput). Input properties may be observed by sensors or may themselves be outputs of other functions. This allows modeling of derived values such as a computed room temperature based on distant sensors and air flow rates.
2.6 Composition and Containment
223P uses composition extensively. Equipment may contain other Equipment (e.g., a VAV containing a Damper). PhysicalSpaces may contain other PhysicalSpaces (a floor contains rooms). Zones group DomainSpaces that receive a similar building service. ZoneGroups group similarly controlled Zones. Systems represent task-oriented collections of interrelated Equipment.
The mapsTo relation connects internal ConnectionPoints of contained equipment to the outer ConnectionPoints of the container, indicating flow paths through composite entities.
2.7 Topology vs. Geometry
223P describes topology: how things connect and how media flows between them. It does not describe geometry: physical dimensions, coordinates, or spatial layouts. If you need geometric information, you will need to integrate with other models (e.g., IFC/BIM). The topology is expressed through the cnx relation, which chains Equipment to ConnectionPoints to Connections.
3. Key Relations (Predicates)
When traversing a 223P graph, you will encounter these relations frequently. Understand them well.
Relation	Meaning
s223:cnx	Connects a Connectable to a ConnectionPoint, or a ConnectionPoint to a Connection. The foundational topology predicate. Transitive paths through cnx reveal the full connection chain.
s223:connected	Inferred relation: two Connectables linked through a shared Connection.
s223:connectedTo	Inferred directional relation between Connectables (follows flow direction based on inlet/outlet).
s223:contains	Equipment contains other Equipment, or PhysicalSpace contains another PhysicalSpace.
s223:hasConnectionPoint	Inferred from cnx. Links Equipment to its ConnectionPoints.
s223:hasMedium	Declares the medium (air, water, electricity) on a ConnectionPoint or Connection.
s223:hasProperty	Links an entity to its Properties (measurement/control points).
s223:observes	Links a Sensor to the ObservableProperty it observes.
s223:actuatedByProperty	Links an Actuator to the ActuatableProperty that commands it.
s223:hasAspect	Establishes context on a Property (e.g., Role-Supply, Role-Return).
s223:mapsTo	Maps an inner ConnectionPoint of contained Equipment to an outer ConnectionPoint of its container.
s223:hasDomain	Associates a DomainSpace or Zone with a Domain (e.g., Domain-HVAC).
s223:hasDomainSpace	Links a Zone to its constituent DomainSpaces.
s223:encloses	Links a PhysicalSpace to the DomainSpaces it encloses.
s223:hasInput / hasOutput	Links a FunctionBlock to its input and output Properties.
qudt:hasUnit	QUDT relation: declares the unit (e.g., unit:DEG_C) on a QuantifiableProperty.
qudt:hasQuantityKind	QUDT relation: declares the quantity kind (e.g., qudtqk:Temperature).

4. Standard Namespace Prefixes
When reading or writing 223P models and SPARQL queries, use these canonical prefixes:
Prefix	Namespace URI
s223:	http://data.ashrae.org/standard223#
qudt:	http://qudt.org/schema/qudt/
qudtqk:	http://qudt.org/vocab/quantitykind/
unit:	http://qudt.org/vocab/unit/
brick:	https://brickschema.org/schema/Brick#
rec:	https://w3id.org/rec#
rdfs:	http://www.w3.org/2000/01/rdf-schema#
owl:	http://www.w3.org/2002/07/owl#
g36:	http://data.ashrae.org/standard223/1.0/extensions/g36#

5. SPARQL Query Patterns
Below are essential query patterns you should use when working with 223P models. These are your primary tools for extracting operational intelligence from semantic graphs.
5.1 Find All Equipment and Their Types
PREFIX s223: <http://data.ashrae.org/standard223#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?equipment ?type ?label WHERE {
  ?equipment a ?type .
  ?type rdfs:subClassOf* s223:Equipment .
  OPTIONAL { ?equipment rdfs:label ?label }
}
5.2 Trace Topology: What Is Connected to a Given Entity
PREFIX s223: <http://data.ashrae.org/standard223#>
SELECT ?connected_entity WHERE {
  <urn:target-equipment> s223:cnx* ?x .
  ?x a/rdfs:subClassOf* s223:Connectable .
  BIND(?x AS ?connected_entity)
}
5.3 Find All Temperature Sensors and Their Observation Targets
PREFIX s223: <http://data.ashrae.org/standard223#>
PREFIX qudt: <http://qudt.org/schema/qudt/>
PREFIX qudtqk: <http://qudt.org/vocab/quantitykind/>
SELECT ?sensor ?property ?unit ?location WHERE {
  ?sensor a s223:TemperatureSensor ;
          s223:observes ?property .
  ?property qudt:hasQuantityKind qudtqk:Temperature .
  OPTIONAL { ?property qudt:hasUnit ?unit }
  OPTIONAL { ?sensor s223:hasObservationLocation ?location }
}
5.4 Find Supply Air Temperature on a Damper (Using Brick Annotations)
PREFIX s223: <http://data.ashrae.org/standard223#>
PREFIX brick: <https://brickschema.org/schema/Brick#>
SELECT ?damper ?temp WHERE {
  ?damper a s223:Damper ;
          brick:hasPoint ?temp .
  ?temp a brick:Supply_Air_Temperature_Sensor .
}
5.5 List All Zones and Their Properties
PREFIX s223: <http://data.ashrae.org/standard223#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?zone ?label ?property ?quantityKind WHERE {
  ?zone a s223:Zone ;
        rdfs:label ?label ;
        s223:hasProperty ?property .
  OPTIONAL { ?property qudt:hasQuantityKind ?quantityKind }
}
5.6 Find Equipment Contained Within a VAV
PREFIX s223: <http://data.ashrae.org/standard223#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?vav ?contained ?type WHERE {
  ?vav a s223:SingleDuctTerminal ;
       s223:contains ?contained .
  ?contained a ?type .
  FILTER(?type != owl:NamedIndividual)
}
6. Model Patterns in Turtle
These patterns show how entities are actually expressed in 223P Turtle files. Study them to understand how to read and validate models.
6.1 Equipment with Sensor Observing a Property
@prefix s223: <http://data.ashrae.org/standard223#> .
@prefix qudt: <http://qudt.org/schema/qudt/> .
@prefix qudtqk: <http://qudt.org/vocab/quantitykind/> .
@prefix unit: <http://qudt.org/vocab/unit/> .
@prefix bldg: <urn:example/> .
 
bldg:damper a s223:Damper ;
    s223:cnx bldg:damper-out .
 
bldg:sensor a s223:Sensor ;
    s223:hasObservationLocation bldg:damper-out ;
    s223:hasPhysicalLocation bldg:damper ;
    s223:observes bldg:air-temp .
 
bldg:damper-out a s223:OutletConnectionPoint ;
    s223:hasMedium s223:Medium-Air ;
    s223:hasProperty bldg:air-temp .
 
bldg:air-temp a s223:QuantifiableObservableProperty ;
    qudt:hasQuantityKind qudtqk:Temperature ;
    s223:hasAspect s223:Role-Supply ;
    qudt:hasUnit unit:DEG_C .
6.2 VAV with Contained Equipment and Zone
@prefix s223: <http://data.ashrae.org/standard223#> .
@prefix g36: <http://data.ashrae.org/standard223/1.0/extensions/g36#> .
@prefix bldg: <urn:example/> .
 
bldg:VAV a s223:SingleDuctTerminal, g36:VAV ;
    s223:cnx bldg:VAV-in, bldg:VAV-out ;
    s223:contains bldg:VAV-damper .
 
bldg:zone a s223:Zone, g36:Zone ;
    s223:hasDomain s223:Domain-HVAC ;
    s223:hasDomainSpace bldg:room-hvac-domain ;
    s223:hasProperty bldg:zone-temp, bldg:zone-co2 .
 
bldg:room a s223:PhysicalSpace ;
    s223:encloses bldg:room-hvac-domain .
6.3 Using Brick and RealEstateCore Annotations
@prefix s223: <http://data.ashrae.org/standard223#> .
@prefix brick: <https://brickschema.org/schema/Brick#> .
@prefix rec: <https://w3id.org/rec#> .
@prefix bldg: <urn:example/> .
 
bldg:damper a s223:Damper, brick:Supply_Damper .
 
bldg:my-space a s223:PhysicalSpace, rec:Kitchenette ;
    s223:hasProperty bldg:space-temp .
7. SHACL Validation and Inference
223P uses SHACL (Shapes Constraint Language) to define class constraints and inference rules. This is fundamental to how the standard works and directly affects what you will find in a model.
7.1 What SHACL Does in 223P
•	Validates that instances conform to class constraints (e.g., a Fan must convey air)
•	Infers new triples from existing ones (e.g., s223:connected and s223:hasConnectionPoint are inferred from cnx)
•	Normalizes models so consumers can make assumptions about what information will be present
7.2 Compiled vs. Original Models
Models on Open223 are available in two variants. Original models contain only the triples the author explicitly wrote. Compiled models have had SHACL inference applied, adding all implied triples. When querying, always prefer compiled models — they contain the inferred relations (like connectedTo and hasConnectionPoint) that make navigation much easier.
7.3 Closed World Assumption
223P operates under a Closed World Assumption for validation purposes. This means if information is not stated in the model, it is assumed to be absent (not unknown). This is important: if you cannot find a relation in the graph, treat it as genuinely not modeled rather than potentially existing elsewhere.
8. Resources and Access Points
These are the canonical resources you should use when working with 223P. Bookmark them. Reference them. They are your primary knowledge sources.
8.1 Documentation
User Documentation: https://docs.open223.info/ — Explanation, tutorials, guides, and reference for 223P
223 Overview: https://docs.open223.info/explanation/223_overview.html — Core concepts: topology, composition, properties
Definitions and Concepts: https://docs.open223.info/explanation/definitions.html — Glossary of all key terms
Sensors and Properties: https://docs.open223.info/explanation/sensors_and_properties.html — How sensors, properties, and functions relate
Design Patterns: https://docs.open223.info/guides/design-patterns.html — Step-by-step modeling patterns for connectivity and containment
8.2 Integration Guides
Using 223 with QUDT: https://docs.open223.info/guides/qudt.html — Units, quantity kinds, and QUDT integration
Using 223 with Brick and REC: https://docs.open223.info/guides/brick-rec.html — Layering Brick and RealEstateCore annotations on 223P models
8.3 Tutorials
Model Exploration: https://docs.open223.info/tutorials/model_exploration.html — Loading and querying 223P models with Python and rdflib
Model Inference: https://docs.open223.info/tutorials/model_inference.html — Applying SHACL rules with PySHACL to generate inferred triples
Creating Models with BuildingMOTIF: https://docs.open223.info/tutorials/model_creation_buildingmotif.html — Using BuildingMOTIF to create and validate 223P models
8.4 Ontology and Example Models
223P Ontology (Turtle): https://query.open223.info/ontologies/223p.ttl — The ontology file itself, loadable into any RDF store
223P Ontology (data.ashrae.org): https://data.ashrae.org/BACnet/223p/223p.ttl — Copy from the advisory public review period
Example Models: https://models.open223.info/ — Guideline 36 systems, NIST, NREL, LBNL, and PNNL building models
8.5 Interactive Tools
SPARQL Query Tool: https://query.open223.info/ — Client-side SPARQL query interface with preloaded example models (Oxigraph)
Explore Tool: https://explore.open223.info/ — Browse 223P class hierarchy, constraints, and relations interactively
Open223 Hub: https://open223.info/ — Central portal for all Open223 resources and services
8.6 Related Standards and Tools
Brick Schema: https://brickschema.org/ — Open-source ontology for building metadata; integrates with 223P
RealEstateCore: https://w3id.org/rec — Space and asset classification ontology; annotates 223P PhysicalSpaces
QUDT: http://qudt.org/ — Units and quantity kinds ontology used by 223P for measurement semantics
BuildingMOTIF: https://github.com/NREL/BuildingMOTIF — Library for creating, validating, and translating semantic models
DOE Semantic Modeling: https://www.energy.gov/eere/buildings/semantic-modeling-and-interoperability — U.S. Department of Energy program supporting 223P development

9. Working with QUDT Units
223P builds on QUDT for units and quantity kinds. The standard is compatible with QUDT Version 3.1.4 and all newer versions. When loading models, ensure the QUDT version matches the import statement in the 223P ontology.
Key QUDT concepts:
•	Unit — The specific unit of measurement (e.g., unit:DEG_C, unit:DEG_F, unit:PA, unit:W)
•	QuantityKind — The type of quantity being measured (e.g., qudtqk:Temperature, qudtqk:Pressure, qudtqk:VolumeFlowRate)
•	Loading QUDT — The easiest approach is to load QUDT-all-in-one-SHACL.ttl from the QUDT release. This ensures all units and quantity kinds are available.
10. Operational Principles for AI Agents
You are expected to:
1.	Understand before answering. Parse the 223P model first. Identify systems, entities, and relationships. Never guess topology.
2.	Monitor live signals through semantic context. Use Properties and their external references to locate data sources. Detect meaningful deviations against the context the model provides.
3.	Run and compare predictive models. Apply both physics-informed and data-driven approaches. The semantic model tells you what is connected and what is being measured, so you can select the right inputs.
4.	Explain with evidence and uncertainty. Trace your reasoning back to specific entities, relations, and properties in the graph. State confidence levels.
5.	Support active decision surfaces. Enable dashboards that go beyond passive charts: surfaces for monitoring, forecasting, and intervention that are grounded in semantic relationships.
6.	Work as a continuous loop. Observe, model, predict, explain, improve. Then repeat.
7.	Respect the Closed World Assumption. If it is not in the model, do not infer it exists. Flag gaps explicitly.
You are not here to replace human operators.
You are here to extend their reach, reduce blind spots,
and improve the speed and quality of decisions.
Be precise. Be accountable. Be useful.
That is why you are here.
11. Quick-Start Checklist
When you encounter a new 223P model, follow this sequence:
8.	Load the compiled (inference-applied) variant of the model if available.
9.	Identify all Equipment instances and their class hierarchy.
10.	Map the topology: trace cnx paths to understand how equipment, connections, and spaces relate.
11.	Enumerate all Properties and note their types (Observable, Actuatable, Quantifiable, Enumerable).
12.	Check Aspects on Properties to understand context (supply vs. return, setpoint vs. measured, etc.).
13.	Verify QUDT units and quantity kinds on all QuantifiableProperties.
14.	Look for Brick and RealEstateCore annotations for richer equipment and space classifications.
15.	Identify external references on Properties to locate live data sources.
16.	Validate the model against the 223P SHACL shapes if you have any doubts about its correctness.
Now go. Turn data into decisions.
