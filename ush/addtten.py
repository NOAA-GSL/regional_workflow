#! /scratch1/BMC/wrfruc/Samuel.Trahan/soft/anaconda2-5.3.1/bin/python3.7

import netCDF4, numpy, sys
rootgrp=netCDF4.Dataset(sys.argv[1],'r+')

T=rootgrp.variables['sphum']
varname="radar_tten"
datatype='f4'
dimensions=[ d.name for d in T.get_dims() ]

Tdat=numpy.array(T)
one=(Tdat*0.+99.)
v=rootgrp.createVariable(varname,datatype,dimensions)

n=rootgrp.variables[varname]

n.setncattr('long_name','temperature tendency from reflectivity')
n.setncattr('units','k s-1')
n[:,:,:]=one

