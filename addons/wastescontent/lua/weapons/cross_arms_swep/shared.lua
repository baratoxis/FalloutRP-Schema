/**
* Adding crossed arms.
*
* @author Kyle James
* @version 8 August 2019
*/

SWEP.Author					= "Mattzimann & Oninoni & Flynt"
SWEP.Purpose				= "You can now cross your arms behind your back!"
SWEP.Instructions 			= "Click to cross your arms."

SWEP.Category 				= "Darkwater Entertainment's Fallout DarkRP | Scripted Weapons Pack"
SWEP.PrintName				= "Cross Arms"
SWEP.Spawnable				= true

SWEP.Base = "animation_swep_base"

if CLIENT then
	function SWEP:GetGesture()
		return {
	        ["ValveBiped.Bip01_R_UpperArm"] = Angle(3.809, 15.382, 2.654),
	        ["ValveBiped.Bip01_R_Forearm"] = Angle(-63.658, 1.8 , -84.928),
	        ["ValveBiped.Bip01_L_UpperArm"] = Angle(3.809, 15.382, 2.654),
	        ["ValveBiped.Bip01_L_Forearm"] = Angle(53.658, -29.718, 31.455),

	        ["ValveBiped.Bip01_R_Thigh"] = Angle(4.829, 0, 0),
	        ["ValveBiped.Bip01_L_Thigh"] = Angle(-8.89, 0, 0),
	    }
	end
end
