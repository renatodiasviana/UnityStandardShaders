Shader "Custom/FirstCubeReflectionShader"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_ReflectionMap("Cube Reflection Amp", CUBE) = "white" {}
		_NormalTex("Normal map (RGB)", 2D) = "bump" {}
		_MetallicTex("Mettalic map (RGB)", 2D) = "black" {}
		_RoughnessTex("Roughness map (RGB)", 2D) = "black" {}
		_EmissionTex("Emission map (RGB)", 2D) = "black" {}
		_ReflectionController("Reflection Controller", Range(0,5)) = 0.0
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _NormalTex;
		sampler2D _MetallicTex;
		sampler2D _RoughnessTex;
		sampler2D _EmissionTex;
		samplerCUBE _ReflectionMap;

		struct Input
		{
			float2 uv_MainTex;
			float3 worldRefl;
			float3 viewDir;
			INTERNAL_DATA
		};

		fixed4 _Color;
		float _ReflectionController;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		float3 BlendColor(float3 albedoColor, float3 reflectionColor, float metallic)
		{
			// Reflection Color é a cor do CUBE MAP, albedo Color é cor da superfície
			float reflection = clamp(metallic * _ReflectionController, 0.0, 1.0);
						
			// INTERPOLAÇÃO LINEAR
			float3 finalColor = albedoColor * (1.0 - reflection) + reflectionColor * reflection;
			finalColor = clamp(finalColor, 0.0, 1.0);

			return finalColor;
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo comes from a texture tinted by color
			fixed4 albedoColor = tex2D(_MainTex, IN.uv_MainTex);
			fixed3 normalMap = UnpackNormal(tex2D(_NormalTex, IN.uv_MainTex)).rgb;
			fixed4 metallicMap = tex2D(_MetallicTex, IN.uv_MainTex);
			fixed4 roughnessMap = tex2D(_RoughnessTex, IN.uv_MainTex);
			fixed4 emissionMap = tex2D(_EmissionTex, IN.uv_MainTex);

			o.Normal = normalMap;	

			//fixed3 worldRefl = reflect(IN.viewDir, o.Normal);
			//fixed4 reflectionMap = texCUBE(_ReflectionMap, worldRefl);
			fixed4 reflectionMap = texCUBE(_ReflectionMap, IN.worldRefl);

			float3 finalColor = BlendColor(albedoColor.rgb, reflectionMap.rgb, metallicMap.r);
			o.Albedo = finalColor * _Color.rgb;

			// Transformando roughness em smoothness
			float smoothness = (1.0 - roughnessMap.r);
			o.Smoothness = smoothness;

			o.Metallic = metallicMap.r;
			o.Emission = emissionMap;
			o.Alpha = albedoColor.a;
		}
		ENDCG
	}
		FallBack "Diffuse"
}
