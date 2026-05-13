package com.mantiq.controller;

import com.mantiq.model.*;
import com.mantiq.repository.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/groups")
public class GroupController {

    private final GroupRepository       groupRepository;
    private final GroupMemberRepository memberRepository;
    private final GroupTreeRepository   groupTreeRepository;
    private final UserRepository        userRepository;
    private final TreeRepository        treeRepository;

    public GroupController(GroupRepository groupRepository,
                           GroupMemberRepository memberRepository,
                           GroupTreeRepository groupTreeRepository,
                           UserRepository userRepository,
                           TreeRepository treeRepository) {
        this.groupRepository     = groupRepository;
        this.memberRepository    = memberRepository;
        this.groupTreeRepository = groupTreeRepository;
        this.userRepository      = userRepository;
        this.treeRepository      = treeRepository;
    }

    // Meine Gruppen: GET /api/groups?userId=X
    @GetMapping
    public ResponseEntity<?> meineGruppen(@RequestParam Integer userId) {
        List<Map<String, Object>> result = groupRepository.findByMemberId(userId).stream()
            .map(g -> gruppeZuMap(g, userId)).toList();
        return ResponseEntity.ok(result);
    }

    // Suche: GET /api/groups/search?q=...
    @GetMapping("/search")
    public ResponseEntity<?> suchen(@RequestParam String q, @RequestParam Integer userId) {
        List<Map<String, Object>> result = groupRepository.searchByName(q).stream()
            .map(g -> gruppeZuMap(g, userId)).toList();
        return ResponseEntity.ok(result);
    }

    // Gruppe erstellen: POST /api/groups
    // Body: { "userId": X, "name": "...", "groupType": "UNIVERSITY|MODULE", "description": "..." }
    @PostMapping
    public ResponseEntity<?> erstellen(@RequestBody Map<String, Object> body) {
        Integer userId    = (Integer) body.get("userId");
        String  name      = (String)  body.get("name");
        String  groupType = (String)  body.get("groupType");

        if (name == null || name.isBlank())
            return ResponseEntity.badRequest().body(Map.of("fehler", "Name erforderlich"));

        User ersteller = userRepository.findById(userId).orElse(null);
        if (ersteller == null) return ResponseEntity.notFound().build();

        MantiqGroup gruppe = new MantiqGroup();
        gruppe.setName(name.trim());
        gruppe.setGroupType(groupType != null ? groupType : "MODULE");
        gruppe.setDescription((String) body.get("description"));
        gruppe.setInviteCode(generiereCode());
        gruppe.setCreatedBy(ersteller);
        groupRepository.save(gruppe);

        // Ersteller automatisch als Admin hinzufuegen
        GroupMember admin = new GroupMember();
        admin.setGroup(gruppe);
        admin.setUser(ersteller);
        admin.setRole("ADMIN");
        memberRepository.save(admin);

        return ResponseEntity.ok(gruppeZuMap(gruppe, userId));
    }

    // Gruppe beitreten (per Invite-Code): POST /api/groups/join
    // Body: { "userId": X, "inviteCode": "ABC123" }
    @PostMapping("/join")
    public ResponseEntity<?> beitreten(@RequestBody Map<String, Object> body) {
        Integer userId     = (Integer) body.get("userId");
        String  inviteCode = (String)  body.get("inviteCode");

        MantiqGroup gruppe = groupRepository.findByInviteCode(inviteCode).orElse(null);
        if (gruppe == null)
            return ResponseEntity.badRequest().body(Map.of("fehler", "Ungültiger Einladungscode"));

        User nutzer = userRepository.findById(userId).orElse(null);
        if (nutzer == null) return ResponseEntity.notFound().build();

        if (memberRepository.existsByGroupIdAndUserId(gruppe.getId(), userId))
            return ResponseEntity.badRequest().body(Map.of("fehler", "Bereits Mitglied"));

        GroupMember mitglied = new GroupMember();
        mitglied.setGroup(gruppe);
        mitglied.setUser(nutzer);
        memberRepository.save(mitglied);

        return ResponseEntity.ok(Map.of("nachricht", "Gruppe beigetreten: " + gruppe.getName()));
    }

    // Gruppe verlassen: DELETE /api/groups/{id}/leave?userId=X
    @DeleteMapping("/{id}/leave")
    public ResponseEntity<?> verlassen(@PathVariable Integer id, @RequestParam Integer userId) {
        GroupMember m = memberRepository.findByGroupIdAndUserId(id, userId).orElse(null);
        if (m == null) return ResponseEntity.notFound().build();
        memberRepository.delete(m);
        return ResponseEntity.noContent().build();
    }

    // Baeume der Gruppe: GET /api/groups/{id}/trees
    @GetMapping("/{id}/trees")
    public ResponseEntity<?> gruppenBaeume(@PathVariable Integer id) {
        List<Map<String, Object>> result = groupTreeRepository.findByGroupId(id).stream()
            .map(gt -> {
                Map<String, Object> m = new HashMap<>();
                m.put("treeId",      gt.getTree().getId());
                m.put("title",       gt.getTree().getTitle());
                m.put("description", gt.getTree().getDescription() != null ? gt.getTree().getDescription() : "");
                m.put("sharedBy",    gt.getSharedBy().getDisplayName() != null
                                     ? gt.getSharedBy().getDisplayName() : gt.getSharedBy().getEmail());
                m.put("stepCount",   gt.getTree().getSteps() != null ? gt.getTree().getSteps().size() : 0);
                return m;
            }).toList();
        return ResponseEntity.ok(result);
    }

    // Baum mit Gruppe teilen: POST /api/groups/{id}/trees
    // Body: { "userId": X, "treeId": Y }
    @PostMapping("/{id}/trees")
    public ResponseEntity<?> baumTeilen(@PathVariable Integer id,
                                        @RequestBody Map<String, Integer> body) {
        Integer userId = body.get("userId");
        Integer treeId = body.get("treeId");

        MantiqGroup gruppe = groupRepository.findById(id).orElse(null);
        Tree baum = treeRepository.findById(treeId).orElse(null);
        User teiler = userRepository.findById(userId).orElse(null);

        if (gruppe == null || baum == null || teiler == null)
            return ResponseEntity.notFound().build();
        if (!memberRepository.existsByGroupIdAndUserId(id, userId))
            return ResponseEntity.badRequest().body(Map.of("fehler", "Nur Mitglieder können Bäume teilen"));
        if (groupTreeRepository.existsByGroupIdAndTreeId(id, treeId))
            return ResponseEntity.badRequest().body(Map.of("fehler", "Baum bereits geteilt"));

        GroupTree gt = new GroupTree();
        gt.setGroup(gruppe);
        gt.setTree(baum);
        gt.setSharedBy(teiler);
        groupTreeRepository.save(gt);

        return ResponseEntity.ok(Map.of("nachricht", "Baum geteilt"));
    }

    private Map<String, Object> gruppeZuMap(MantiqGroup g, Integer userId) {
        boolean istMitglied = memberRepository.existsByGroupIdAndUserId(g.getId(), userId);
        int mitgliederZahl  = memberRepository.findByGroupId(g.getId()).size();
        Map<String, Object> m = new HashMap<>();
        m.put("id",          g.getId());
        m.put("name",        g.getName());
        m.put("groupType",   g.getGroupType());
        m.put("description", g.getDescription() != null ? g.getDescription() : "");
        m.put("inviteCode",  g.getInviteCode() != null ? g.getInviteCode() : "");
        m.put("memberCount", mitgliederZahl);
        m.put("isMember",    istMitglied);
        return m;
    }

    private String generiereCode() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();
    }
}
