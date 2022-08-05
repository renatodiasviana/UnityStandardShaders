struct TessellationFactors
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

#define TESS_PATCH_FUNC(func_name, appdata, tess) \
TessellationFactors func_name(InputPatch<appdata, 3> patch) \
{ \
	TessellationFactors f; \
	f.edge[0] = tess; \
	f.edge[1] = tess; \
	f.edge[2] = tess; \
	f.inside = tess; \
	return f; \
}

#define TESS_HULL_FUNC(func_name, patchFunction, appdata, partitioning) \
				[UNITY_domain("tri")] \
				[UNITY_outputcontrolpoints(3)] \
				[UNITY_outputtopology("triangle_cw")] \
				[UNITY_partitioning(partitioning)] \
				[UNITY_patchconstantfunc(patchFunction)] \
				appdata func_name(InputPatch<appdata, 3> patch, uint id : SV_OutputControlPointID) {return patch[id];}

//TESS_HULL_FUNC(MyHullProgram, "MyPatchFunc", appdata, "fractional_odd")
//TESS_HULL_FUNC(MyHullProgram, "MyPatchFunc", appdata, "fractional_even")
//TESS_HULL_FUNC(MyHullProgram, "MyPatchFunc", appdata, "pow2")
//TESS_HULL_FUNC(MyHullProgram, "MyPatchFunc", appdata, "integer")

#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
												patch[0].fieldName * barycentricCoordinates.x + \
												patch[1].fieldName * barycentricCoordinates.y + \
												patch[2].fieldName * barycentricCoordinates.z;

#define TESS_DOMAIN_FUNC(func_name, disp_func_name, appdata, output) \
[UNITY_domain("tri")] \
output func_name(TessellationFactors factors, OutputPatch<appdata, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) \
{ \
	appdata data; \
	MY_DOMAIN_PROGRAM_INTERPOLATE(pos) \
	MY_DOMAIN_PROGRAM_INTERPOLATE(normal) \
	MY_DOMAIN_PROGRAM_INTERPOLATE(tangent) \
	MY_DOMAIN_PROGRAM_INTERPOLATE(uv) \
	return disp_func_name(data); \
}