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

1. Data where captured (digitalized) from the source publication using the annotation tool "Dugnadsportalen" (https://github.com/gbif-norway/dugnad). The publication describes the species inventory of freshwater lakes (and some streams) in Norway. Locations of each species are listed in separate chapters and organized by municipality and county. Names of waterbodies listed in the publication where mapped to the current offical Norwegian gazetteer of lacustrine waterbodies curated by the The Norwegian Water Resources and Energy Directorate "Innsjødatabase" downloaded 2018-XX-XX. Due to changes in naming conventions, spelling differences etc. the matching where done by manuall curation. The following field (description | DwC mapping in paranteses) from this gazzetteer where linked to orginal occurrences; vatnLnr (offical Norwegian lake running number | dwc:locationID), name (current official name of waterbody | dwc:waterBody), Shape (polygon geometry of waterbody outline | dwc:footprintWKT). Orginal names as provided by the publication was stored in the field dwc:verbatimeLocality when entered by the user. 

2. Data where downloaded from "Dugnadsportalen" and parsed to tabular format (see R script;)

3. 

