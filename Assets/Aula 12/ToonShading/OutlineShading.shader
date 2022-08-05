Shader "Unlit/OutlineShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlinePower("Outline Power", Range(0,1.0)) = 0.5
    }
    SubShader
    {
        /*Pass
        {
			Tags { "RenderType" = "Opaque" "LightMode" = "UniversalForward"}
			LOD 100

			ZTest on
			ZWrite on

			Stencil
			{
				Ref 128 // Define o valor da máscara
				Comp always // Define uma função de comparação que passa ou rejeita ("always signifa aprovado sempre")
				Pass replace // Define uma ação
			}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "AutoLightFixed.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "OutlineShading.cginc"

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				float diffuse = clamp(dot(i.normal, _WorldSpaceLightPos0.xyz), 0.0, 1.0);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				float4 resultColor = col * diffuse * _LightColor0 * LIGHT_ATTENUATION(i);
				return resultColor;
			}
            ENDCG
        }*/

		/*Pass
		{
			Tags { "RenderType" = "Opaque" "LightMode" = "ForwardAdd"}
			LOD 100

			Blend One One // Additive blend

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			//#include "AutoLightFixed.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "OutlineShading.cginc"

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				float3 dir = (_WorldSpaceLightPos0.xyzw - i.worldPos).xyz;
				float distanceToLight = length(dir);

				float diffuse = clamp(dot(i.normal, normalize(dir)), 0.0, 1.0);

				float lightIntensity = 1.0 / pow(distanceToLight, 2.0);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				float4 resultColor = col * diffuse * _LightColor0 * LIGHT_ATTENUATION(i) * lightIntensity;
				return resultColor;
			}
			ENDCG
		}*/

		Pass
		{
			Tags { "RenderType" = "Opaque"}
			LOD 100

			ZTest on
			ZWrite on

			//Blend One One // Additive blend

			Stencil
			{
				Ref 128 // Definir o valor da máscara
				Comp NotEqual // Compara valor 128 e passa no teste quando não for igual
			}

			Cull front // Definindo que eu quero renderizar apenas o Back

			CGPROGRAM
			#pragma vertex tess
			#pragma fragment frag

			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "AutoLightFixed.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "OutlineShading.cginc"

			float4 _OutlineColor;
			float _OutlinePower;

			v2f tess(appdata v)
			{
				v2f o;

				float4 pos = v.pos;
				pos.xyz += v.normal * 0.001 * _OutlinePower;

				o.pos = UnityObjectToClipPos(pos);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, pos);
				
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float4 resultColor = _OutlineColor;
				return resultColor;
			}
			ENDCG
		}
    }
}
