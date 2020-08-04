It can be a challenge to maintain documentation & diagrams up-to-date when there are changes going on in an environment you might be responsible for the design or strategy of or general day to day front line support. Being part of a larger team or having some level of oversight responsibility means changes can occur to configurations that are not well socialised and all of a sudden what you knew or thought about a deployment of a component is no longer current which in itself can be a problem. Depending on the function you are responsible for, the changes might not directly matter that much to you hence why I say it can as opposed to it will. The changes that occur can impact processes such as the ones listed below but not just these, this list is just some of the key things impacted:

- General Configuration Management & Desired State Configuration
- Change control
- Documentation and Diagram maintenance
- Architecture and Strategy planning
- Service Dependency Mapping & Systems Monitoring
- Capacity, Availability & Disaster Recovery Planning
- Troubleshooting & Root Cause Analysis

So I've developed some scripts to help overcome some of these challenges so I can quickly and easily see what’s been changing within an Azure environment or information about items generically about Azure itself by just flagging changes in configuration or published information from Azure between two points in time and then using additional tools to analyse the differences (such as Notepad++ or even Github Desktop). What is key here is not so much the PowerShell scripting I developed and used (as there are always many languages and tools!) but primarily what I was trying to achieve and achieve it with relative simplicity. As you will see, I run some scripts, compare some output and get a quick indication of what’s changed and where to look to get the detail. These types of scripts are not so much required if config change logging is used and ingested by a reporting tool or if you have dynamic documentation tools that capture changes and thus automatically produce updated diagrams and so forth.

Scripts were initially written in a PowerShell 5.1.19041.1 environment later updated to 7.0.3 with Az Module 3.7.0 through 4.4.0 on a Windows 10 VM. I kept the scripts in the user “Documents” folder including scripts that contain functions and the scripts utilise “[environment]::getfolderpath(“mydocuments”) to determine script locations and also output folder structure for text file output. The scripts do not have any special error containment or control so file system issues or similar will probably break the script and end up with slabs of error messages.

You can find further information about the scripts generally at http://www.roity.com/tech/blog

