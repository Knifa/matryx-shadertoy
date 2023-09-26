bool in_bounding_box(vec2 coord_, vec2 center_, vec2 size_) {
    vec2 min = center_ - size_ / 2.0;
    vec2 max = center_ + size_ / 2.0;

    return coord_.x >= min.x && coord_.x <= max.x && coord_.y >= min.y && coord_.y <= max.y;
}

bool in_bounding_box(ivec2 coord_, ivec2 center_, ivec2 size_) {
    ivec2 min = center_ - size_ / 2;
    ivec2 max = center_ + size_ / 2;

    return coord_.x >= min.x && coord_.x <= max.x && coord_.y >= min.y && coord_.y <= max.y;
}

bool in_bounding_circle(vec2 coord_, vec2 center_, float radius_) {
    return length(coord_ - center_) <= radius_;
}

bool in_bounding_circle(ivec2 coord_, ivec2 center_, int radius_) {
    return length(vec2(coord_ - center_)) <= float(radius_);
}

bool in_bounding_polygon(vec2 coord_, vec2 poly_coords[8], int count) {
    bool inside = false;
    for (int i = 0, j = count - 1; i < count; j = i++) {
        if (((poly_coords[i].y > coord_.y) != (poly_coords[j].y > coord_.y)) &&
            (coord_.x < (poly_coords[j].x - poly_coords[i].x) * (coord_.y - poly_coords[i].y) / (poly_coords[j].y - poly_coords[i].y) + poly_coords[i].x)) {
            inside = !inside;
        }
    }
    return inside;
}
