# WiseOMF - An OMF Wrapper for Testbed Runtime

This repository contains the server side implementation of the OMF ([Orbit Measurement Framework](http://mytestbed.net/projects/omf/wiki/OMF_Main_Page)) wrapper for testbed runtime
as well as the client side helpers for writing experiments with OEDL (OMF Experiment Description Language).


## Overview

You might be interested in the following files and directories:

* [wiseomf-gem](../master/wiseomf-gem) - implementation of the wise_omf gem which can be found at [rubygems.org](https://rubygems.org/gems/wise_omf)
* **client side**
  * [ec](../master/ec) - examples for writing testbed runtime experiments in OEDL
* **server side**
  * [lib](../master/lib) - implementations of OMF resources
  * [wiseomfrc.rb](../master/wiseomfrc.rb) - script for starting the server side OMF wrapper (resource controller)
  * [config.yml](../master/config.yml) - configuration of the OMF wrapper


## Tutorials

* [Client Side Tutorial](wiki/Client-Side-Tutorial)
   A tutorial teaching you how to install and configure the OMF experiment controller and how to write experiments for the testbed runtime in OEDL using the wise_omf gem as helper.
* [Message Documentation](wiki/Message-Documentation)
   This pages contains a documentation of all possible commands that can be send to the testbed runtime via the wise_omf client helper. Furthermore this page contains a description of the message format of all messages beeing send to and from the client.