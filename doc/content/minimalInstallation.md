# Instalation into your vehicle

## Step 1 - Prepare scripts

All you need to do when preparing for insert this script, is to copy all **lua** files from [`/src/FS17_RealGPSMod/sdk/`](../../src/FS17_RealGPSMod/sdk/) into your `scripts` folder (or any other desired folder) under your mod.

Also do not forget to copy entire FS17_RealGPSMap folder into `mods`.

## Step 2 - Prepare `modDesc.xml`

When you've prepared script for insertion into your vehicle, you need to register it in `modDesc.xml`.

Please see example of such `modDesc.xml` in [Example modDesc configuration](exampleModDesc.md)

## Step 3 - Prepare 3D space

PDA map must be somewhere inserted. To achieve this, you need to set empty transform group in you model in Giants EDITOR. PDA map will link into this node.

## Step 4 - Setup vehicle's xml file

After that you will need to tell to script when map should be inserted. Please take a look at example in [Example configuration](exampleConfig.md), where you can find more info about how setup is done - all with brief explanation.
