# Real PDA map mod

This is deevloper's guide for installing Real GPS mod intor your vehicle

## Instalation into your vehicle

### Step 1 - Prepare scripts

All you need to do when preparing for insert this script, is to copy all lua files from `sdk/` into your `scripts` folder (or any other desired folder) under your mod.

### Step 2 - Prepare `modDesc.xml`

When you've prepared script for insertion into your vehicle, you need to register it in `modDesc.xml`.

Please see example of such `modDesc.xml` in `sdk/modDesc_example.xml`

### Step 3 - Prepare 3D space

PDA map must be somewhere inserted. To achieve this, you need to set empty transform group in you model in Giants EDITOR. PDA map will link into this node.

### Step 4 - Setup vehicle's xml file

After that you will need to tell to script where map should be inserted. Please take a look at example file in `sdk/vehicle_example.xml`, where you can find more info about how setup is done - all with explanation.

## Mod details

Author: Martin Fabík
Email: mar.fabik@gmail.com

GitHub project: https://github.com/LoogleCZ/FS17-RealGPSMod
If anyone found errors, please contact me at mar.fabik@gmail.com or report it on GitHub

version ID   - 1.0.0
version date - 2018-09-27 01:00

## Support

You can support this mod by

- Sharing it under [original link](https://github.com/LoogleCZ/FS17-RealGPSMod/releases) (link to GitHub releases)
- Contributing to this mod via email suggestions, git pull requsts, etc...
- Financial support through PayPal at [https://www.paypal.me/MartinFabik](https://www.paypal.me/MartinFabik)

## License 

Free for non-commercial usage; for commercial use please contact me at mar.fabik@gmail.com
