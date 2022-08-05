Shader "Unlit/FirstUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Shininess("Shininess", Range(0.1, 1.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct appdata
            {
                float4 pos : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;				
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal :TEXCOORD1;
			};

            sampler2D _MainTex;
            float4 _MainTex_ST;

			half _Shininess;

            v2f vert(appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.pos);
				o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
				return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

				// Diffuse component
				float NdotL = dot(i.normal, _WorldSpaceLightPos0.xyz);
				float diffuse = clamp(NdotL, 0.0, 1.0);
				float3 diffuseColor = col.rgb * diffuse * _LightColor0;

				// Specular component
				float3 halfVector = normalize(_WorldSpaceLightPos0.xyz + _WorldSpaceCameraPos.xyz);
				float NdotH = dot(i.normal.xyz, halfVector);
				float specular = clamp(NdotH, 0.0, 1.0);
				specular = pow(specular, _Shininess * 128.0);
				float3 specularColor = col.rgb * specular * _LightColor0;

                // apply fog
				float4 resultColor = float4(diffuseColor + specularColor, 1.0);
				return resultColor;
            }
            ENDCG
        }
    }
}
