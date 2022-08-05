Shader "Custom/FirstToonOutlineShading"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Shininess("Shininess", Range(0, 1.0)) = 0.5
		_Tones("Number of tones", Range(2.0, 20.0)) = 4.0
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlinePower("Outline Power", Range(0,1.0)) = 0.5
	}
	SubShader
	{
		// Esse Shader possui passos de render!

		// Primeiro rendiza o objeto com toon shading 

		Tags { "RenderType" = "Opaque" }
		LOD 200

		Stencil // MáSCARA EM TEMPO-REAL
		{
			Ref 128 // Define o valor da máscara
			Comp always // Define uma função de comparação que passa ou rejeita ("always signifa aprovado sempre")
			Pass replace // Define uma ação
		}

		CGPROGRAM

		#pragma surface surf MyCustomLighting fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		half _Shininess;
		half _Tones;
		fixed4 _Color;

		struct Input
		{
			float2 uv_MainTex;
		};

		struct SurfaceOutputCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			fixed Shininess;
			fixed Alpha;
		};

		float4 LightingMyCustomLighting(SurfaceOutputCustom s, half3 lightDir, half3 viewDir, half atten)
		{
			// Calculate Diffuse light
			half NdotL = round(clamp(dot(s.Normal, lightDir) * atten, 0.0, 1.0) * _Tones) / _Tones;
			float3 diffuseColor = s.Albedo * _LightColor0.rgb * NdotL;

			// Calculate Specular light
			float3 halfVector = normalize(lightDir + viewDir);
			half NdotH = clamp(dot(s.Normal, halfVector), 0.0, 1.0);
			NdotH = round(pow(NdotH, _Shininess * 128.0) * _Tones) / _Tones;

			float3 specularColor = s.Albedo * _LightColor0.rgb * NdotH;

			float4 resultColor = float4(0.0, 0.0, 0.0, 1.0);
			resultColor.rgb = clamp(diffuseColor + specularColor, 0.0, 1.0);

			return resultColor;
		}

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf(Input IN, inout SurfaceOutputCustom o)
		{
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Shininess = _Shininess;
			o.Alpha = 1.0;
		}

		ENDCG

		// Segundo passo de render, rendiza o objeto em Outline 

		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 200

		Stencil
		{
			Ref 128 // Definir o valor da máscara
			Comp NotEqual // Compara valor 128 e passa no teste quando não for igual
		}

		Cull front // Definindo que eu quero renderizar apenas o Back

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows alpha:blend vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		fixed4 _OutlineColor;
		float _OutlinePower;

		struct Input
		{
			float2 uv_MainTex;
			float3 viewDir;
			INTERNAL_DATA
		};

		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)

		// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v)
		{
			v.vertex.xyz += v.normal * 0.001 * _OutlinePower;
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Calcula o fresnell
			float3 resultColor = _OutlineColor;

			o.Albedo = resultColor * _Color;
			o.Alpha = _OutlineColor.a;
		}
		ENDCG

	}

	FallBack "Diffuse"
}