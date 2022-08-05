Shader "Unlit/FirstGeometryShader"
{
	Properties
	{
		_Color("Color", color) = (1, 1, 1, 0)
		_MainTex("Texture", 2D) = "white" {}
		_GrassHight("Grass Hight", Range(0, 1.0)) = 0.3
		_GrassLength("Grass Lenght", Range(0.1, 1.0)) = 0.3
		_GrassCount("Grass Count", Range(1, 20.0)) = 1.0
		_WindDir("Wind Direction", Vector) = (0.0, 0.0, 0.0, 1.0)
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		Cull Off
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma hull MyHullFunc
			#pragma domain MyDomainFunc

			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "MyTessellation.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
			};

			struct v2g
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float4 color : COLOR;
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 tangent : TEXCOORD2;
				float4 color : COLOR;
				UNITY_FOG_COORDS(3)		
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _GrassHight;
			float _GrassCount;
			float _GrassLength;
			float4 _WindDir;
			static float RandomSeed = 1.0;

			float CalculateRandomValue(float min, float max)
			{
				float randomno = frac(sin(dot(RandomSeed, float2(12.9898, 78.233)))*43758.5453);

				RandomSeed++;

				return lerp(min, max, randomno);
			}

			float RandomPos(float noise)
			{
				return CalculateRandomValue(-0.5 * noise, 0.5 * noise);
			}

			float RandomColorIntensity()
			{
				return CalculateRandomValue(0.25, 1.0);
			}

			v2g vert(appdata v)
			{
				v2g o;

				o.vertex = v.vertex;
				o.uv = v.uv;
				o.normal = v.normal;
				o.tangent = v.tangent;
				o.color = float4(1.0, 1.0, 1.0, 1.0);

				return o;
			}

			// Declaring tessellation hull function
			TESS_PATCH_FUNC(MyPatchFunc, appdata, _GrassCount)
			TESS_HULL_FUNC(MyHullFunc, "MyPatchFunc", appdata, "fractional_odd")
			TESS_DOMAIN_FUNC(MyDomainFunc, vert, appdata, v2g)

			g2f geo_to_frag(v2g v)
			{
				g2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.tangent = UnityObjectToWorldNormal(v.normal);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o, v.vertex);

				return o;
			}

			void generateGrass(v2g vertex, float noise, float3 offset, inout TriangleStream<g2f> triStream)
			{
				v2g v1, v2, v3;
				float4 randomPos = float4(RandomPos(1.0), 0.0, RandomPos(1.0), 0.0);

				v1 = vertex;
				v1.color = float4(0.5, 0.5, 0.5, 1.0) * RandomColorIntensity();
				v1.vertex += float4(offset, 0.0) + randomPos;

				v2 = vertex;
				v2.color = float4(0.5, 0.5, 0.5, 1.0) * RandomColorIntensity();
				v2.vertex += float4(offset * -1.0, 0.0) + randomPos;

				v3 = vertex;
				v3.color = float4(1.0, 1.0, 1.0, 1.0) * RandomColorIntensity();

				float3 windAnimation = clamp(_WindDir * pow(sin(_Time.y), 2.0) * _WindDir.w, 0.0, 1.0);

				v3.vertex += float4(vertex.normal * float3(1.0, noise.r + 0.25, 1.0) * _GrassHight + windAnimation, 0.0) + randomPos;

				float3 v2v1 = normalize(v2.vertex - v1.vertex);
				float3 v3v1 = normalize(v3.vertex - v1.vertex);
				float3 normal = normalize(cross(v2v1, v3v1));

				v1.normal = normal;
				v2.normal = normal;
				v3.normal = normal;

				triStream.Append(geo_to_frag(v1));
				triStream.Append(geo_to_frag(v2));
				triStream.Append(geo_to_frag(v3));

				triStream.RestartStrip();
			}

			v2g GetBaryCentric(v2g IN[3])
			{
				v2g baryCentric;

				baryCentric.vertex = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3.0;
				baryCentric.normal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3.0;
				baryCentric.uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3.0;
				baryCentric.tangent = (IN[0].tangent + IN[1].tangent + IN[2].tangent) / 3.0;

				return baryCentric;
			}

			[maxvertexcount(60)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				g2f o;

				float3 offset = normalize(mul(UNITY_MATRIX_V, float4(0.1, 0.0, 0.0, 1.0)).xyz) * 0.3 * _GrassLength;

				fixed4 noise;

				v2g baryCentric = GetBaryCentric(IN);

				noise = tex2Dlod(_MainTex, float4(baryCentric.uv, 0, 0));
				generateGrass(baryCentric, noise.x, offset, triStream);
			}

			fixed4 frag(g2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = _Color * i.color;
				
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}

			ENDCG
		}
	}
}
