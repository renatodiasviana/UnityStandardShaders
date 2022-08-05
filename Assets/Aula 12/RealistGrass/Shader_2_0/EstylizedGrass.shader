Shader "Unlit/EstylizedGrass"
{
	Properties
	{
		_Color("Color", color) = (1, 1, 1, 0)
		_BaseGrassColor("Grass Color on the ground", color) = (0.1, 0.1, 0.1, 0)
		_MainTex("Grass Texture", 2D) = "white" {}
		_GrassGroupTex("Grass Group Texture", 2D) = "white" {}
		_HightNoiseTex("Hight Noise Texture", 2D) = "white" {}
		_DistributionMaskTex("Grass Distribution Mask Texture", 2D) = "white" {}
		_WindDirTex("Wind Direction Texture", 2D) = "bump" {}
		_CollisionDirTex("Collision Direction Texture", 2D) = "black" {}
		_WindFrequencyController("Wind Frequency Controller", Range(0, 1.0)) = 0.3
		_DistributionGrassController("Distribution Grass Controller", Range(0, 1.0)) = 0.3
		_WindDir("Wind Direction Multiplier", Vector) = (1.0, 0.0, 1.0, 1.0)
		_GrassLength("Grass Lenght", Range(0.1, 1.0)) = 0.3
		_GrassCount("Grass Count", Range(1, 20.0)) = 1.0
		_GrassHight("Grass Segment Hight", Range(0, 1.0)) = 0.3
		_GrassSegmentCount("Grass Segment Count", Range(1, 6)) = 1
		_ShadingTones("Shading Tones Count", Range(1, 30)) = 1
		_Shininess("Shininess", Range(0.1, 1.0)) = 1.0
	}
	SubShader
	{
		Pass
		{
			Tags { "RenderType" = "Transparent" "Queue"="Transparent" "LightMode" = "ForwardBase" }

			Blend SrcAlpha OneMinusSrcAlpha

			Cull Off
			LOD 100
			ZTest on
			ZWrite on

			CGPROGRAM

			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma hull MyHullFunc
			#pragma domain MyDomainFunc

			#include "MyGrassGeometry.cginc"

			// make fog work
			#pragma multi_compile_fog alphatest:_Cutoff alpha

			fixed4 frag(g2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				if (col.a < 0.25)
						discard;

				col.rgb *= i.color;
				UNITY_APPLY_FOG(i.fogCoord, col);

				// Calculate Diffuse light
				half NdotL = round(clamp(dot(i.normal, _WorldSpaceLightPos0.xyz), 0.0, 1.0) * _ShadingTones) / _ShadingTones;
				float3 diffuseColor = col * _LightColor0.rgb * NdotL;

				// Calculate Specular light based on fresnel
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.pos);
				float OneMinusNdotV = pow(1.0 - clamp(dot(i.normal, viewDir), 0.0, 1.0), 2.0) * _Shininess * 5.0;
				OneMinusNdotV = round(OneMinusNdotV * _ShadingTones) / _ShadingTones;

				float3 specularColor = col * _LightColor0.rgb * OneMinusNdotV;

				float4 resultColor = float4(0.0, 0.0, 0.0, col.a);
				resultColor.rgb = clamp(diffuseColor + specularColor, 0.0, col.a) * LIGHT_ATTENUATION(i);

				// apply fog
				return resultColor;
			}
		
			ENDCG
		}

		Pass
		{
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "LightMode" = "ForwardAdd" }

			Blend SrcAlpha OneMinusSrcAlpha

			Cull Off
			LOD 100
			ZTest on
			ZWrite on

			CGPROGRAM

			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma hull MyHullFunc
			#pragma domain MyDomainFunc

			#include "MyGrassGeometry.cginc"

			// make fog work
			#pragma multi_compile_fog alphatest:_Cutoff alpha

			fixed4 frag(g2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				if (col.a < 0.25)
						discard;

				//col.rgb *= i.color;
				UNITY_APPLY_FOG(i.fogCoord, col);

				// Calculate Diffuse light
				half NdotL = round(clamp(dot(i.normal, _WorldSpaceLightPos0.xyz), 0.0, 1.0) * _ShadingTones) / _ShadingTones;
				float3 diffuseColor = length(col.rgb) * _LightColor0.rgb * NdotL * i.color;

				float4 resultColor = float4(0.0, 0.0, 0.0, col.a);
				resultColor.rgb = diffuseColor * LIGHT_ATTENUATION(i);

				// apply fog
				return resultColor;
			}

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma hull MyHullFunc
			#pragma domain MyDomainFunc

			#include "MyGrassGeometry.cginc"

			#pragma target 4.6
			#pragma multi_compile_shadowcaster

			float4 frag(g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				if (col.a < 0.75)
					discard;

				return UnityEncodeCubeShadowDepth((length(i.pos) + unity_LightShadowBias.x) * _LightPositionRange.w);
			}

			ENDCG
		}
	}
}
