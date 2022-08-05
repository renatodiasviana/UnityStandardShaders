Shader "Custom/FirstPBRCustonShading"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_NormalTex("Normal map (RGB)", 2D) = "bump" {}
		_MetallicTex("Mettalic map (RGB)", 2D) = "black" {}
		_RoughnessTex("Roughness map (RGB)", 2D) = "black" {}
		_EmissionTex("Emission map (RGB)", 2D) = "black" {}
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM

		#pragma surface surf _CustomPBRLighting fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _NormalTex;
		sampler2D _MetallicTex;
		sampler2D _RoughnessTex;
		sampler2D _EmissionTex;
		fixed4 _Color;

		struct Input
		{
			float2 uv_MainTex;
			float3 worldRefl;
			float3 viewDir;
			INTERNAL_DATA
		};

		struct SurfaceOutputCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			fixed3 Reflection;
			fixed Roughness;
			fixed Metallic;
			fixed Alpha;
		};

		float CalculationNormalizationFactor(half NdotL, half NdotV)
		{
			return 4.0 * NdotL * NdotV;
		}

		float CalculateDistributionFactor(float NdotH, half roughness)
		{
			float powedRoughness = pow(roughness, 2.0);
			float powedNdotH = pow(NdotH, (1.001 - roughness) * 128.0);

			float result = powedRoughness / (3.1415 * powedRoughness * powedNdotH);
			return powedNdotH;
		}

		float CalculateCookTorrance(half VdotH, half NdotH, half NdotV, half NdotL)
		{
			float factorA = (2.0 * NdotH * NdotV) / VdotH;
			float factorB = (2.0 * NdotH * NdotL) / VdotH;

			float result = min(factorA, factorB);
			result = min(result, NdotL);

			return result;
		}

		float CalculateFresnelFactor(half NdotV, half refractionIndex)
		{
			float fresnel = pow(1.0 - NdotV, 5.0);
			return refractionIndex * fresnel;
		}

		float CalculatePBRReflection(half3 normal, half3 lightDir, half3 viewDir, half roughness, half metallic)
		{
			float3 halfVector = normalize(lightDir + viewDir);
			float VdotH = clamp(dot(viewDir, halfVector), 0.0, 1.0);
			float NdotH = clamp(dot(normal, halfVector), 0.0, 1.0);
			float NdotV = clamp(dot(normal, viewDir), 0.0, 1.0);
			float NdotL = clamp(dot(normal, lightDir), 0.0, 1.0);

			float normalizationFactor = CalculationNormalizationFactor(NdotL, NdotV);
			float distributionFactor = CalculateDistributionFactor(NdotH, roughness);
			float fresnelFactor = CalculateFresnelFactor(NdotV, metallic * roughness);
			float geometryFactor = CalculateCookTorrance(VdotH, NdotH, NdotV, NdotL);

			float BRDF = (distributionFactor * fresnelFactor * geometryFactor) / normalizationFactor;
			BRDF = clamp(BRDF, 0.0, 1.0);

			return BRDF;
		}

		float4 Lighting_CustomPBRLighting(SurfaceOutputCustom s, half3 lightDir, half3 viewDir, half atten)
		{
			// Calculate Diffuse light
			half NdotL = clamp(dot(s.Normal, lightDir) * atten, 0.0, 1.0);
			float3 diffuseColor = _LightColor0.rgb * NdotL * s.Albedo;

			// Calculate Specular light (Brilho da fonte da luz)
			float3 halfVector = normalize(lightDir + viewDir);
			half NdotH = clamp(dot(s.Normal, halfVector), 0.0, 1.0);
			NdotH = pow(NdotH,	(1.0 - s.Roughness) * 128.0);

			float3 specularColor = _LightColor0.rgb * NdotH * s.Reflection;

			// Calculate PBR factor
			half PBRFactor = CalculatePBRReflection(s.Normal, lightDir, viewDir, s.Roughness, s.Metallic) * atten;
			float3 PBRColor = s.Reflection * PBRFactor;
	
			float4 resultColor = float4(0.0, 0.0, 0.0, 1.0);
			resultColor.rgb = clamp(diffuseColor + specularColor + PBRColor, 0.0, 1.0);

			return resultColor;
		}

		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf(Input IN, inout SurfaceOutputCustom o)
		{
			// Albedo comes from a texture tinted by color
			fixed4 baseColorMap = tex2D(_MainTex, IN.uv_MainTex);
			fixed3 normalMap = UnpackNormal(tex2D(_NormalTex, IN.uv_MainTex)).rgb;
			fixed4 metallicMap = tex2D(_MetallicTex, IN.uv_MainTex);
			fixed4 roughnessMap = tex2D(_RoughnessTex, IN.uv_MainTex);
			fixed4 emissionMap = tex2D(_EmissionTex, IN.uv_MainTex);

			// A Unity limita o nível de detalhe do Mapa especular no máximo 8
			float loadLevel = ((1.0 - roughnessMap.r) / 1.0) * 8.0;
			float4 worldReflectionMap = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, IN.worldRefl.xyz, loadLevel);

			float dialletric = clamp((1.0 - metallicMap.r), 0.015, 1.0);

			o.Reflection = worldReflectionMap.rgb * metallicMap.r;
			o.Albedo = _Color.rgb * lerp(baseColorMap.rgb * dialletric, baseColorMap.rgb, dialletric);

			o.Normal = normalMap;
			o.Metallic = metallicMap.r;

			// Transformando roughness
			o.Roughness = roughnessMap.r;

			o.Emission = emissionMap;

			o.Alpha = baseColorMap.a;
		}

		ENDCG
	}

	FallBack "Standard"
}