Shader "Custom/FirstTesselationShader"
{
	Properties
	{
		_Color("Color", color) = (1,1,1,0)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_NormalTex("Normal Map", 2D) = "bump" {}
		_HightTex("Hight Map", 2D) = "black" {}
		_RoughnessTex("Roughness Map", 2D) = "gray" {}
		_Tess("Tessellation", Range(1,32)) = 4
		_EdgeLength("Edge Length", Range(0.1,32)) = 5
		_Displacement("Displacement", Range(0, 1.0)) = 0.3
		_Metallic("Metallic", Range(0, 1.0)) = 0.3
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 300
		CGPROGRAM
		#pragma surface surf Standard addshadow fullforwardshadows vertex:disp tessellate:tessFixed nolightmap
		#pragma target 4.0

		#include "Tessellation.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

		struct Input
		{
			float2 uv_MainTex;
		};
	   
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _NormalTex;
		sampler2D _HightTex;
		sampler2D _RoughnessTex;

		float _Tess;		
		float _Displacement;
		float _Metallic;
		float _EdgeLength;
	   
		float4 tessFixed()
		{
			return _Tess;
		}

		float4 tessDistance(appdata v0, appdata v1, appdata v2) 
		{
			float minDist = 0.1;   //destância onde o tesselation estará no máximo
			float maxDist = 10.0;  //destância onde o tesselation estará desligado
			return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
		}

		float4 tessEdge(appdata v0, appdata v1, appdata v2)
		{
			return UnityEdgeLengthBasedTess(v0.vertex, v1.vertex, v2.vertex, _Tess);
		}

		float4 tessPhong(appdata v0, appdata v1, appdata v2)
		{
			return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, _Tess);
		}

		void disp(inout appdata v)
		{
			float d = tex2Dlod(_HightTex, float4(v.texcoord.xy, 0, 0)).r * _Displacement;
			v.vertex.xyz += v.normal * d;
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo comes from a texture tinted by color
			fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			fixed4 roughness = tex2D(_RoughnessTex, IN.uv_MainTex);
	
			o.Normal = UnpackNormal(tex2D(_NormalTex, IN.uv_MainTex));

			o.Albedo = albedo.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = 1.0 - roughness.r;
			o.Alpha = 1.0;
		}

		ENDCG
	
	} FallBack "Diffuse"

}
