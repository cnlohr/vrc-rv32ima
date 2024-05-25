#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

public class WorldgenGeoGen : MonoBehaviour
{
	[MenuItem("Tools/Create WorldgenGeoGen")]
	static void CreateMesh_()
	{
		int vertices = 512; // Generate 512 primitives
		Mesh mesh = new Mesh();
		mesh.vertices = new Vector3[1];
		mesh.bounds = new Bounds(new Vector3(0, 0, 0), new Vector3(10000, 10000, 10000));
		mesh.SetIndices(new int[vertices], MeshTopology.Points, 0, false, 0);
		AssetDatabase.CreateAsset(mesh, "Assets/vrc-rv32ima/WorldgenGeo/WorldgenGeo.asset");
	}
}
#endif