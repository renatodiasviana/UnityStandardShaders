Shader "Custom/TerrainTextureShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _WaterTex ("Water texture (RGB)", 2D) = "white" {}
		_LandTex("Land texture (RGB)", 2D) = "white" {}
		_GrassTex("Grass texture (RGB)", 2D) = "white" {}
		_SnowTex("Snow texture (RGB)", 2D) = "white" {}
		_MaskTex("Mask texture (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
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

        sampler2D _WaterTex;
		sampler2D _LandTex;
		sampler2D _GrassTex;
		sampler2D _SnowTex;
		sampler2D _MaskTex;

        struct Input
        {
            float2 uv_WaterTex;
        };

        half _Glossiness;
        half _Metallic;
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
            fixed4 water = tex2D (_WaterTex, IN.uv_WaterTex * 5.0);
			fixed4 land = tex2D(_LandTex, IN.uv_WaterTex * 5.0);
			fixed4 grass = tex2D(_GrassTex, IN.uv_WaterTex);
			fixed4 snow = tex2D(_SnowTex, IN.uv_WaterTex);
			fixed4 mask = tex2D(_MaskTex, IN.uv_WaterTex);
            
			fixed3 color = water.rgb * mask.r; // river
			color += land.rgb * mask.g; // land
			color += grass.rgb * mask.b; // grass
			color += snow.rgb * (1.0 - mask.a); // snow
			
			// Metallic and smoothness come from slider variables
			o.Albedo = color.rgb * _Color;
			o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
