float VanillaDiffuse(vec3 normal) {
    return min(normal.x * normal.x * 0.6
             + normal.y * normal.y * 0.25 * (3.0 + normal.y)
             + normal.z * normal.z * 0.8, 1.0);
}
