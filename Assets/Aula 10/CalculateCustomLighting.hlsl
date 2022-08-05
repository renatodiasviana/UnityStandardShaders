#ifndef CALCULATE_CUSTOM_LIGHTING
#define CALCULATE_CUSTOM_LIGHTING

void CalculateCustomLighting_float(float3 albedo, float3 normal, float3 viewDir, float tones, out float3 result)
{
	float3 Light_Direction = float3(0.5, 0.5, 0.5);
	float3 Light_Color = float3(1.0, 1.0, 1.0);

	#ifndef SHADERGRAPH_PREVIEW
	
		Light light = GetMainLight();

		Light_Direction = light.direction;
		Light_Color = light.color;

	#endif
		
	// Somente luz difusa
	half NdotL = clamp(round(dot(normal, Light_Direction) * tones) / tones, 0.0, 1.0);
	result = albedo * Light_Color * NdotL;
}

#endif