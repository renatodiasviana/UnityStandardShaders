Shader "Unlit/ToonShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlinePower("Outline Power", Range(0,1.0)) = 0.5
    }
    SubShader
    {
        Pass
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
        }
    }
}
