# WiseOMF - An OMF Wrapper for Testbed Runtime

This repository contains the server side implementation of the OMF ([Orbit Measurement Framework](http://mytestbed.net/projects/omf/wiki/OMF_Main_Page)) wrapper for testbed runtime
as well as the client side helpers for writing experiments with the OEDL (OMF Experiment Description Language).


## Overview

You might be interested in the following files and directories:

* [wiseomf-gem](../master/wiseomf-gem) - implementation of the wise_omf gem which can be found at [rubygems.org](https://rubygems.org/gems/wise_omf)
* **client side**
  * [ec](../master/ec) - examples for writing testbed runtime experiments in OEDL
* **server side**
  * [lib](../master/lib) - implementations of OMF resources
  * [wiseomfrc.rb](../master/wiseomfrc.rb) - script for starting the server side OMF wrapper (resource controller)
  * [config.yml](../master/config.yml) - configuration of the OMF wrapper


## Further Information

Visit the [wiki](https://github.com/wisebed/wiseomf/wiki) for tutorials and additional documentation.