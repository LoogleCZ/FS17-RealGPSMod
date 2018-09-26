# Example of modDesc.xml file

Here zou can find steps how to register specialization into your vehicle. Note that this is not full `modDesc.xml`

```
<?xml version="1.0" encoding="utf-8" standalone="no" ?>
<modDesc descVersion="39">
	<!-- other nodes goes here -->
	<extraSourceFiles>
		<!-- other nodes goes here -->
		<!-- Source file for map events - need to be present!! -->
	   <sourceFile filename="path/to/RealPDAMapEvent.lua"/> <!-- @author	Martin Fabík -->
	</extraSourceFiles>
	
	<specializations>
		<!-- other nodes goes here -->
		<!-- Main speciliaztion for real PDA map - don't forget to add it into your vehicleType -->
		<specialization name="RealPDAMap" className="RealPDAMapSpec" filename="path/to/RealPDAMapSpec.lua" /> <!-- @author	Martin Fabík -->
	</specializations>
	
	<vehicleTypes>
		<!-- other nodes goes here -->
		<type name="yourVehicleType" className="Vehicle" filename="$dataS/scripts/vehicles/Vehicle.lua">
			<!-- other nodes goes here -->
			<!-- register specilization under vehicleType -->
			<specialization name="RealPDAMap" />
		</type>
	</vehicleTypes>
	
	<!-- other nodes goes here -->
</modDesc>
```