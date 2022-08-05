Shader "Unlit/SecondUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
			Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase"}
			LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

			#include "UnityCG.cginc"
			//#include "AutoLightFixed.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "MyFirstUnlit.cginc"

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
        }

		Pass
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
			#include "MyFirstUnlit.cginc"

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
		}
    }
}
