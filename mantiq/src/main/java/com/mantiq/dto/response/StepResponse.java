package com.mantiq.dto.response;

import java.util.List;

public record StepResponse(
        Integer id,
        String title,
        Integer position,
        boolean completed,
        List<TaskResponse> tasks
) {}
