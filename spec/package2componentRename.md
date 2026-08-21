TASK: standardize our naming of folders that contain Typescript files as being 'component's -- not packages. 

EXECUTION MODE: lights-out — you have pre-approval to create and edit files without asking for confirmation. Proceed directly with implementation.


CONTEXT:
  Repo: ~/build-tools
  Platform workspace: javascript/ (NX monorepo, run all NX commands from there)

DETAILS:

    At each milestone point, make sure all validation passes.   (run both formatting and validation as very last step)
    if validation passes, then git commit to working branch
    
    First:
    Read @javascript/update-markdown-uml/README.md#terminology to understand the convention (use 'component' not 'package')


    Milestone 1:
        the use of the name _PACKAGE_INFO.md does not respect this convention. 
        Change all _PACKAGE_INFO.md  -> _COMPONENT_INFO.md  in code base.

        top level @javascript/README: 
            change 'package diagrams' to 'component diagrams' 
        
    




UPDATE FORMATTING BEFORE VALIDATION:
  cd ~/build-tools/javascript
  npx nx run build-tools-workspace:update-all-format

VALIDATION:
  cd ~/build-tools/javascript
  npx nx run build-tools-workspace:check-format             # must exit 0
  npx nx run-many -t build,test --skip-nx-cache             # must exit 0


[![Free Palestine!](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
