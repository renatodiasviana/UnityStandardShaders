Shader "Custom/BlendTexture"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("First Texture (RGB)", 2D) = "white" {}
		_SecondTex("Second Texture (RGB)", 2D) = "white" {}
		_MaskTex("Mask Texture (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_MaskIntensity("Intensity of the mask", Range(0,5)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _SecondTex;
		sampler2D _MaskTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
		half _MaskIntensity;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 firstTexture = tex2D(_MainTex, IN.uv_MainTex);
			fixed4 secondTexture = tex2D(_SecondTex, IN.uv_MainTex * 5.0);
			fixed4 maskTexture = tex2D(_MaskTex, IN.uv_MainTex);

			float maskTextureUpdated = maskTexture.r * _MaskIntensity;
			maskTextureUpdated = clamp(maskTextureUpdated, 0.0, 1.0);

			fixed3 color = (firstTexture.rgb * maskTextureUpdated) + ((1.0 - maskTextureUpdated) * secondTexture.rgb);

			o.Albedo = color * _Color.rgb;
            
			// Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
