# Huitfeldt-Kaas (1918) - Raw data from transcribations and DwC-A mapping

----------------------------------------------------------
* **Source publication:** Huitfeldt-Kaas (1918) Ferskvandsfiskenes utbredelse og indvandring i Norge : med et tillæg om krebsen, Kristiania : Centraltrykkeriet,106 p.   https://github.com/gbif-norway/dugnad
* **Source URL:** https://urn.nb.no/URN:NBN:no-nb_digibok_2006120500031 
* **Project:** https://dugnad.gbif.no/nb_NO/project/huitfeldt-kaas
* **Project setup:** https://github.com/gbif-norway/dugnad/blob/master/projects/huitfeldt-kaas.yaml
* **Metadata:** https://gbif.vm.ntnu.no/ipt/resource?r=huitfeldt-kaas_1918  
-----------------------------------------------------------

# Methods
## methodSteps

1. **Data where captured (digitalized)** from the source publication using the annotation tool "Dugnadsportalen" (https://github.com/gbif-norway/dugnad). The publication describes the species inventory of freshwater lakes (and some streams) in Norway. Locations of each species are listed in separate chapters and organized by municipality and county. Names of waterbodies listed in the publication where mapped to the current offical Norwegian gazetteer of lacustrine waterbodies curated by the The Norwegian Water Resources and Energy Directorate "Innsjødatabase" downloaded 2018-XX-XX. Due to changes in naming conventions, spelling differences etc. the matching where done by manuall curation. The following field (description | DwC mapping in paranteses) from this gazzetteer where linked to orginal occurrences; vatnLnr (offical Norwegian lake running number | dwc:locationID), name (current official name of waterbody | dwc:waterBody), Shape (polygon geometry of waterbody outline | dwc:footprintWKT). Orginal names as provided by the publication was stored in the field dwc:verbatimeLocality when entered by the user. 

2. **Download data** from "Dugnadsportalen" and parsed to tabular format (see R script; "./R/downoad_and_parse_data.R" - this repository). Data are now in flat-file format.

3. **Normalize data** into event core table and occurrence extention table  (see R script; "./R/normalize_data.R"" - this repository). Observations from each lake constitutes an sampling event. Theres is no GUID (uri:uuid) set for events in the raw-data. LocationID (vatn_lnr) is used together with prefix as fieldNumber to create an id unique for the dataset (dwc:fieldNumber). EventIDs (uri:uuid) are generated and stored in table ("./data/raw_data/eventIDs.csv""). Repeated downloads of source data are checked by this table using fieldNumber and assigned new eventID, or reusing existing. Each row in the orginal raw data pre-assigned an occurrenceID (uri:uuid) from Dugnadsportalen.

4. **DwC mapping** are done in several steps to the event and occurrence tables, respectively (see R script; "./R/dwc_mapping.R"" - this repository)

* Assignment of some missing dwc terms and recode 
* Resolving of scientific names. Note: raw data uses names as printed in the orginal publication, these are stored as dwc:taxonRemarks.
*  Set sampling data information. Note: The observations steem from the period 1902 - 1918. As exact data are not known for any of the occurrences dwc:year is set to "1918" and eventDate is set as an intervall "1902/1918".
* decimalLatitude and desimalLongitude are assigned as the centroid of the waterbody polygon (stored in dwc:footprintWKT). In a few cases the waterbody polygon is not present in the raw data (large lakes which exeed the hard limit of field sizes used by the Dugnadsportalen software). In these cases the georefference is optained from the gazzeeter directly (downloaded from http://nedlasting.nve.no/gis/ 2019-01-26). 
* Save occurrence and event tables as tab delimited text files (.txt)



