package com.mantiq.controller;

import com.mantiq.model.Item;
import com.mantiq.model.User;
import com.mantiq.model.UserItem;
import com.mantiq.repository.ItemRepository;
import com.mantiq.repository.UserItemRepository;
import com.mantiq.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/shop")
public class ShopController {

    private final ItemRepository     itemRepository;
    private final UserItemRepository userItemRepository;
    private final UserRepository     userRepository;

    public ShopController(ItemRepository itemRepository,
                          UserItemRepository userItemRepository,
                          UserRepository userRepository) {
        this.itemRepository     = itemRepository;
        this.userItemRepository = userItemRepository;
        this.userRepository     = userRepository;
    }

    // Alle Items: GET /api/shop/items
    @GetMapping("/items")
    public ResponseEntity<?> alleItems() {
        List<Map<String, Object>> items = itemRepository.findAll().stream()
            .map(i -> {
                Map<String, Object> m = new HashMap<>();
                m.put("id",          i.getId());
                m.put("name",        i.getName());
                m.put("description", i.getDescription() != null ? i.getDescription() : "");
                m.put("cost",        i.getCost());
                m.put("itemType",    i.getItemType());
                return m;
            }).toList();
        return ResponseEntity.ok(items);
    }

    // Inventar des Nutzers: GET /api/shop/inventory?userId=X
    @GetMapping("/inventory")
    public ResponseEntity<?> inventar(@RequestParam Integer userId) {
        List<Map<String, Object>> inventar = userItemRepository.findByUserId(userId).stream()
            .map(ui -> {
                Map<String, Object> m = new HashMap<>();
                m.put("itemId",   ui.getItem().getId());
                m.put("name",     ui.getItem().getName());
                m.put("itemType", ui.getItem().getItemType());
                m.put("quantity", ui.getQuantity());
                return m;
            }).toList();
        return ResponseEntity.ok(inventar);
    }

    // Item kaufen: POST /api/shop/buy
    // Body: { "userId": X, "itemId": Y }
    @PostMapping("/buy")
    public ResponseEntity<?> kaufen(@RequestBody Map<String, Integer> body) {
        Integer userId = body.get("userId");
        Integer itemId = body.get("itemId");

        User user = userRepository.findById(userId).orElse(null);
        Item item = itemRepository.findById(itemId).orElse(null);
        if (user == null || item == null) return ResponseEntity.notFound().build();

        if (user.getCoins() < item.getCost())
            return ResponseEntity.badRequest().body(Map.of("fehler", "Nicht genug Münzen"));

        user.setCoins(user.getCoins() - item.getCost());
        userRepository.save(user);

        // Inventar aktualisieren (stackbar)
        Optional<UserItem> vorhandenes = userItemRepository.findByUserIdAndItemId(userId, itemId);
        if (vorhandenes.isPresent()) {
            UserItem ui = vorhandenes.get();
            ui.setQuantity(ui.getQuantity() + 1);
            userItemRepository.save(ui);
        } else {
            UserItem ui = new UserItem();
            ui.setUser(user);
            ui.setItem(item);
            userItemRepository.save(ui);
        }

        return ResponseEntity.ok(Map.of(
            "nachricht", "Gekauft: " + item.getName(),
            "coins",     user.getCoins()
        ));
    }

    // Item benutzen: POST /api/shop/use
    // Body: { "userId": X, "itemId": Y }
    @PostMapping("/use")
    public ResponseEntity<?> benutzen(@RequestBody Map<String, Integer> body) {
        Integer userId = body.get("userId");
        Integer itemId = body.get("itemId");

        User user = userRepository.findById(userId).orElse(null);
        Item item = itemRepository.findById(itemId).orElse(null);
        if (user == null || item == null) return ResponseEntity.notFound().build();

        UserItem ui = userItemRepository.findByUserIdAndItemId(userId, itemId).orElse(null);
        if (ui == null || ui.getQuantity() < 1)
            return ResponseEntity.badRequest().body(Map.of("fehler", "Item nicht im Inventar"));

        // Item-Effekt anwenden
        String nachricht = switch (item.getItemType()) {
            case "STREAK_FREEZE" -> {
                if (user.getStreakBeforeReset() > 0) {
                    user.setStreakDays(user.getStreakBeforeReset());
                    user.setStreakBeforeReset(0);
                    userRepository.save(user);
                    yield "Streak wiederhergestellt! " + user.getStreakDays() + " Tage";
                } else {
                    yield "Keine verlorene Streak zum Wiederherstellen";
                }
            }
            case "COIN_BOOST" -> {
                user.setXp(user.getXp() + 200);
                userRepository.save(user);
                yield "+200 XP erhalten!";
            }
            default -> "Item benutzt";
        };

        // Menge im Inventar verringern
        if (ui.getQuantity() <= 1) {
            userItemRepository.delete(ui);
        } else {
            ui.setQuantity(ui.getQuantity() - 1);
            userItemRepository.save(ui);
        }

        return ResponseEntity.ok(Map.of(
            "nachricht",  nachricht,
            "streakDays", user.getStreakDays(),
            "coins",      user.getCoins()
        ));
    }
}
