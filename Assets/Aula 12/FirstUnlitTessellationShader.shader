// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/FirstUnlitTessellationShader"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
		_NormalTex("Normal Map", 2D) = "bump" {}
		_HightTex("Hight Map", 2D) = "white" {}
		_Tessellation("Tessellation", Range(1,32)) = 4
		_Displacement("Displacement", Range(0, 10.0)) = 0.3
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
			#pragma hull MyHullProgram
			#pragma domain MyDomainProgram

			#pragma target 5.0

            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
            };

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

            struct v2f
            {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 tangent : TEXCOORD2;
				float3 binormal : TEXCOORD3;
				UNITY_FOG_COORDS(1)
            };

            sampler2D _MainTex;
			sampler2D _NormalTex;
			sampler2D _HightTex;
            float4 _MainTex_ST;
			float _Tessellation;
			float _Displacement;

			v2f vert(appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);

				o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.normal = mul(UNITY_MATRIX_P, float4(v.normal, 0.0));
				o.tangent = UnityObjectToWorldNormal(v.tangent);
				o.binormal = normalize(cross(o.normal, o.tangent));

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, v.vertex);
				return o;
			}

			v2f displacement(appdata v)
			{
				v2f o;

				float3 normal = UnpackNormal(tex2Dlod(_NormalTex, float4(v.uv, 0, 0)));
				float3 binormal = normalize(cross(v.normal, v.tangent));

				// Normal Transpose Matrix
				float3x3 local2WorldTranspose = float3x3(v.tangent, binormal, v.normal);

				// Calculate Normal Direction
				normal = mul(local2WorldTranspose, normal);				
				o.normal = normalize(normal + v.normal * 2.0);

				float d = tex2Dlod(_HightTex, float4(v.uv, 0, 3)).r * _Displacement;
				
				float3 modifiedNormal = v.normal.xyz * d * -0.1;
				v.vertex.xyz += modifiedNormal;
				
				o.vertex = v.vertex;
				o.tangent = o.tangent;
				o.uv = v.uv;

				return o;
			}

			TessellationFactors MyPatchConstantFunction(InputPatch<appdata, 3> patch)
			{
				TessellationFactors f;

				f.edge[0] = _Tessellation;
				f.edge[1] = _Tessellation;
				f.edge[2] = _Tessellation;
				f.inside = _Tessellation;

				return f;
			}

			#define HULL_FUNC(name, vertexdata, partitioning) \
				[UNITY_domain("tri")] \
				[UNITY_outputcontrolpoints(3)] \
				[UNITY_outputtopology("triangle_cw")] \
				[UNITY_partitioning(partitioning)] \
				[UNITY_patchconstantfunc("MyPatchConstantFunction")] \
				vertexdata MyHullProgram(InputPatch<vertexdata, 3> patch, uint id : SV_OutputControlPointID) {return patch[id];}

			HULL_FUNC(MyHullProgram, appdata, "fractional_odd")
			//HULL_FUNC(MyHullProgram, appdata, "fractional_even")
			//HULL_FUNC(MyHullProgram, appdata, "pow2")
			//HULL_FUNC(MyHullProgram, appdata, "integer")

			[UNITY_domain("tri")]
			v2f MyDomainProgram(TessellationFactors factors, OutputPatch<appdata, 3> patch,
								float3 barycentricCoordinates : SV_DomainLocation)
			{
				appdata data;

				#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
				patch[0].fieldName * barycentricCoordinates.x + \
				patch[1].fieldName * barycentricCoordinates.y + \
				patch[2].fieldName * barycentricCoordinates.z;

				MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
				MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
				MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
				MY_DOMAIN_PROGRAM_INTERPOLATE(uv)

				#ifdef SHADER_API_D3D11
					data.normal.y *= -1.0;
					data.normal.z *= -1.0;
				#endif

				return displacement(data);
			}

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
				float diffuse = clamp(dot(i.normal, _WorldSpaceLightPos0.xyz), 0.0, 1.0);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				float4 resultColor = col * diffuse * _LightColor0 * LIGHT_ATTENUATION(i);
				//resultColor = float4(i.normal, 1.0);

				return float4(resultColor.xyz + float3(0.1, 0.1, 0.1), 1.0);
            }
            ENDCG
        }
    }
}
