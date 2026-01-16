[![Build and Publish Docker Images and Wheels](https://github.com/OrbitalMicro/wxs-pycrtm/actions/workflows/build-and-publish.yml/badge.svg)](https://github.com/OrbitalMicro/wxs-pycrtm/actions/workflows/build-and-publish.yml)

# pyCRTM - python interface to CRTM.

## Bryan M. Karpowicz, Ph.D. - USRA/GESTAR/NASA 610.1 Global Modeling and Assimilation Office, with Contributions from Patrick Stegmann, Dr.-Ing. - JCSDA

This is a basic python interface to CRTM v2.4.x or CRTMv3. 

The user interface is designed to be very similar to the python RTTOV interface. So, the user sets profiles, passes them to an object for a desired sensor, runs either the forward model/K-matrix, and pulls the brightness temperature/Jacobian/transmission/emissivity out of the object.  


This `README` has 4 parts:

1. Installation -- installing this library
2. Test/Examples -- describing test in testCases subdirectory
3. Importing -- how to use this library in a project.
4. Using the interface -- HOWTO/run through on how to use this interface

- Bryan Karpowicz -- May 7, 2025
---------------------------------------------------------------------------------------- 

## 1. Installation:
For a quicker install experience users may choose to install using the `make_it_so.sh` which will install conda along with the required packages in a miniconda environment `pycrtm`. There are four options `apple_silicon` for Macs with an M2/M3/M4/M? processor, `apple_intel` to install miniconda for Macs with an intel processor, `linux` for all other linux systems, `skip_install` which will skip installing miniconda and attempt to overwrite a `pycrtm` miniconda environment, `skip_create` which will use an existing miniconda pycrtm environment, and `skip_crtm_download` which will skip downloading CRTMv3 in addition to skipping the creation of a miniconda environment. Users are cautioned to look over the script to make sure it will not overwrite existing installs, or fill up your home directory, if space is limited. For example if your system does not have a python install and you a starting from scratch on an M4 Mac simply type:
```
./make_it_so.sh apple_silicon 
```
The script will install miniconda3, CRTMv3, pyCRTM, and run the `test_atms.py` script to verify pyCRTM is working. If you already have miniconda on your machine you can simply run `skip_install` which will just install a pycrtm miniconda environment, CRTMv3, pyCRTM and run the `test_atms.py` script to verify pyCRTM has been installed and is functioning properly. Once installed a user may use the new `pycrtm` conda environment by typing:
```
conda activate pycrtm
```

If that doesn't suit your taste, read on for a more step-by-step approach. 

- Dependencies CRTM, h5py, numpy and scikit-build (install those first, if you don't have them). 
- Configuration
First modify `setup.cfg` to point to the crtm install location (path underneath should contain one of the following: `lib/libcrtm.a`,`lib64/libcrtm.a`, `lib/libcrtm.so`, or `lib64/libcrtm.so`). 
```
[Setup]
# Specify the location of the crtm install
crtm_install =/Users/karpob/pycrtm/ext/CRTMv3/build/
link_from_source_to_path_used = True
[Coefficients]
# source specify coefficient directory will grab little endian binary coefficients and netcdf and link them to path_used
source_path =/Users/karpob/pycrtm/ext/CRTMv3/build/test_data/
# path used by pycrtm to read coefficients
path_used =/Users/karpob/pycrtm/ext/crtm_coefficients
```
Next, pycrtm must have a location where all desired coefficients are expanded in a flat directory. In the configuration above, the installer will create `path_used` and populate it with symbolic links to all available coefficients in `source_path.` If `link_from_source_to_path_used` is set to `False`, `source_path` will be ignored and it is assumed the user has placed coefficients in `path_used` and pyCRTM will search for coefficients in this directory. 
- Installation 
If the user has full write access to their python distribution, it may be installed globally using:
```
pip install .
```
Otherwise, the standard --user option is also available which will install under $HOME/.local/
```
pip install . --user
```
Optionally, you may supply "-v" for a more verbose output while it is installing. Either way, this will take some time as it will symlink coefficients downloaded when you install CRTM, compile the pycrtm module, and link against th crtm library.


Compiler options are handled autmoatically through cmake. On HPC systems this means loading the right set of modules. For example, if you would like pycrtm compiled with intel, you would load the same intel modules you used to build crtm. 

---------------------------------------------------------------------------------------- 

## 2. Tests/Examples:

A few test cases have been developed using input/output grabbed from the CRTM test program.
Two basic scripts which will perform cases 1-4 (stored in $PWD/testCases/data/case[n].h5) from the CRTM test program on 4 OpenMP threads: 
* `$PWD/testCases/test_atms.py`
* `$PWD/testCases/test_cris.py`
These *should* just say Yay, and not produce any plots if successful. 

The following scripts will do the same thing, only this time load up the same 4 profiles multiple times to further test threading with 10 threads (turn your laptop into a space heater more or less).
* `$PWD/testCases/test_atms_threads.py`
* `$PWD/testCases/test_cris_threads.py`
These *should* just say Yay, and not produce any plots if successful. 


The following scripts will run CRTM without aerosols or clouds:
* `$PWD/testCases/test_atms_no_clouds.py`
* `$PWD/testCases/test_cris_no_clouds.py`

For those Jupyter notebook fans, there is even Jupyter notebook example simulating ATMS:
* `$PWD/testCases/test_atms.ipynb`

Additonal More Advanced Examples:
* `$PWD/testCases/test_atms_jacobian.py` Provides cloud jacobians (provide --plot command line argument to generate plot)
* `$PWD/testCases/test_atms_subset_cloudnames.py` Provides example of using a channel subset, along with Cloud type names.
* `$PWD/testCases/test_atms_subset.py` Provides exmaple using a channel subset.
* `$PWD/testCases/test_cris_jacobian.py` Provides cloud/aerosol jacobians (provide --plot command line argument to generate plot)
* `$PWD/testCases/test_cris_subset.py` Provides exmaple using a channel subset.

Active Sensor Examples (Available with CRTMv3.1.x)
* `$PWD/testCases/test_cloudsat.py` tests forward model of active sensor (provide --plot for plot of reflectivity/attenuated reflectivity)
* `$PWD/testCases/test_cloudsat_jacobian.py` tests cloud jacobians (provide --plot for cloud jacobian plot, --attenuated for attenuated reflectivity, otherwise jacobians of reflectivity are plotted.

## 3. Importing 

```Python
from pyCRTM import pyCRTM, profilesCreate
```
---------------------------------------------------------------------------------------- 

## 4. Using the interface (designed to be pretty much like the RTTOV equivalent python library):

Create a profiles data structure using `profilesCreate(nprofiles, nlayers)` which will generate an object with user specified number of profiles, and number of layers in the profiles provided.
```Python
profiles = profilesCreate(4, 92) # will generate an empty object with 4 profiles each with 92 layers. 
```
Once initialized, the user will need to provide values for the desired profiles (see example scripts). Next, the user initializes a crtm instance, set desired parameters, and passes profiles to the CRTM:

```Python
crtmOb = pyCRTM()
crtmOb.sensor_id = sensor_id
crtmOb.nThreads = 4
crtmOb.profiles = profiles
```
Note that while the python interface allows for threads to be set, if your environment has the environment variable `OMP_NUM_THREADS` set, the number of threads will be set by the environment variable, and the argument passed through pyCRTM will be ignored.

Next, the instrument is loaded/number of channels in the output structure are initialized:

```Python
crtmOb.loadInst()
```

Next, the user can run either the forward model (runDirect), or the K-matrix (runK) 
```Python
crtmOb.runDirect()
crtmOb.runK()
```
Finally, the user can pull out desired parameters such as brightness temperatures, Jacobians, or Transmission along path (TauLevels - the derivative will be the weighting function):
```Python
# brightness temperature (nprofiles, nchan):
brightnessTemperature = crtmOb.Bt 

#Transmission (to compute weighting functions) ( nprofiles, nchan, nlayers)
Tau = crtmOb.TauLevels 

#Temperature, Water Vapo[u]r, and Ozone Jacobians ( nprofiles, nchan, nlayers)
O3_Jacobian = crtmOb.O3K
Water_Vapor_Jacobian = crtmOb.QK
Temperature_Jacobian = crtmOb.TK

#Emissivity (nprofiles, nchan)
Emissivity = crtmOb.surfEmisRefl
```
Futher detail on setting profiles can be seen in the testCases directory, however, for quick reference and explanation of profile object:
```Python
        profiles.Angles[i,0] =  # instrument zenith Angle
        profiles.Angles[i,1] =  # instrument azimuth Angle (optional)
        profiles.Angles[i,2] =  # Solar zenith Angle 
        profiles.Angles[i,3] =  # Solar Azimuth Angle 
        profiles.Angles[i,4] =  # Instrument scan angle (see CRTM documentation. e.g., https://ftp.emc.ncep.noaa.gov/jcsda/CRTM/CRTM_User_Guide.pdf)
        profiles.DateTimes[i,0] = #Year
        profiles.DateTimes[i,1] = #Month
        profiles.DateTimes[i,2] = #Day
        profiles.Pi[i,:] =        #Pressure levels/interfaces in hPa
        profiles.P[i,:] =         #Pressure layers 
        profiles.T[i,:] =         #Temperature Layers
        profiles.Q[i,:] =         #Specific humidity  relative to dry air in g/kg
        profiles.O3[i,:] =        #Ozone concentration ppmv (dry air)
        profiles.clouds[i,:,0,0] = #cloud concentration kg/m**2 (optional)
        profiles.clouds[i,:,0,1] = #cloud effective radius microns (optional)
        profiles.aerosols[i,:,0,0] = #aerosol concentration kg/m**2 (optional)
        profiles.aerosols[i,:,0,1] = #aerosol effective radius microns (optional)
        profiles.aerosolType[i] =    #integer representing aerosol type (optional !  1 = Dust 2 = Sea salt-SSAM  
                                     # 3 = Sea salt-SSCM 4 = Sea salt-SSCM2 5 = Sea salt-SSCM3  6 = Organic carbon 7 = Black carbon 8 = Sulfate)
        profiles.cloudType[i] =      #integer representing cloud type (optional)
        profiles.cloudFraction[i,:] = #cloud fraction (optional)
        profiles.climatology[i] =    #integer representing climatology 1-6 modtran style climatological profiles (optional)
        profiles.surfaceFractions[i,:] = # fractions of land, water, snow, ice
        profiles.surfaceTemperatures[i,:] = #surface temperatures (K) of land, water, snow, ice
        profiles.Salinity[i] =              #salinity in PSU
        profiles.windSpeed10m[i] =          #10m windspeed m/s
        profiles.LAI[i] =                   #Leaf area index (optional)
        profiles.windDirection10m[i] =      #10m wind direction (note opposite of atmospheric convention, uses oceanongrapher convention) deg E from N
        # land, soil, veg, water, snow, ice
        profiles.surfaceTypes[i,0] = #land classification type index refer to CRTM documentation (optional)
        profiles.surfaceTypes[i,1] = #soil classification type index refer to CRTM documentation (optional)
        profiles.surfaceTypes[i,2] = #vegetation type classification type index refer to CRTM documentation (optional)
        profiles.surfaceTypes[i,3] = # water type (1=Sea water) check CRTM documentation for others.
        profiles.surfaceTypes[i,4] = # snow type 1=old snow 2=new snow (optional).
        profiles.surfaceTypes[i,5] = # ice type 1= new ice (optional) (optional)

```


---------------------------------------------------------------------------------------- 

