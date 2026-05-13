package com.mantiq;

import com.mantiq.model.User;
import com.mantiq.repository.UserRepository;
import com.mantiq.service.DemoTreeService;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class DemoTreeRunner implements ApplicationRunner {

    private final UserRepository  userRepository;
    private final DemoTreeService demoTreeService;

    public DemoTreeRunner(UserRepository userRepository, DemoTreeService demoTreeService) {
        this.userRepository  = userRepository;
        this.demoTreeService = demoTreeService;
    }

    @Override
    public void run(ApplicationArguments args) {
        for (User user : userRepository.findAll()) {
            demoTreeService.createForUser(user);
        }
    }
}
