package com.airtnt.airtntapp.room;

import java.util.*;
import java.util.stream.Collectors;

import com.airtnt.airtntapp.calendar.CalendarClass;
import com.airtnt.airtntapp.city.CityService;
import com.airtnt.airtntapp.rule.RuleService;
import com.airtnt.airtntapp.state.StateService;
import com.airtnt.airtntapp.user.UserService;
import com.airtnt.airtntapp.user.admin.UserNotFoundException;
import com.airtnt.entity.Room;

import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.repository.query.Param;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.airtnt.entity.Amentity;
import com.airtnt.entity.Category;
import com.airtnt.entity.City;
import com.airtnt.entity.Country;
import com.airtnt.entity.Currency;
import com.airtnt.entity.Image;
import com.airtnt.entity.PriceType;
import com.airtnt.entity.Role;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

import org.springframework.web.bind.annotation.ModelAttribute;

import com.airtnt.entity.RoomGroup;
import com.airtnt.entity.RoomPrivacy;
import com.airtnt.entity.Rule;
import com.airtnt.entity.State;
import com.airtnt.entity.User;

@RestController
public class RoomRestController {

    @Autowired
    private RoomService roomService;

    @Autowired
    private UserService userService;

    @Autowired
    private RuleService ruleService;

    @Autowired
    private StateService stateService;

    @Autowired
    private CityService cityService;

    @PostMapping("/rooms/checkName")
    public String checkName(@Param("id") Integer id, @Param("name") String name) {
        return roomService.isNameUnique(id, name) ? "OK" : "Duplicated";
    }

    @GetMapping("/calendar/{selectedMonth}/{selectedYear}")
    public String getCalendayByYearAndMonth(@PathVariable("selectedYear") int selectedYear,
            @PathVariable("selectedMonth") int selectedMonth) {
        List<String> daysInMonth = CalendarClass.getDaysInMonth(selectedMonth - 1, selectedYear);
        String strDaysInMonth = daysInMonth.stream().map(Object::toString).collect(Collectors.joining(" "));
        GregorianCalendar gCal = new GregorianCalendar(selectedYear, selectedMonth - 1, 1);
        int startInWeek = gCal.get(Calendar.DAY_OF_WEEK); // ng??y th??? m???y trong tu???n ????
        return new JSONObject().put("daysInMonth", strDaysInMonth).put("startInWeek", startInWeek).toString();
    }

    @PostMapping("/room/verify-phone")
    public String verifyPhoneForRoom(@RequestBody Map<String, Integer> payload) {
        Integer roomId = payload.get("roomId");
        Room room = roomService.getRoomById(roomId);
        int isUpdated = userService.verifyPhoneNumber(room.getHost().getId());
        if (isUpdated == 1)
            return "success";
        else
            return "failure";
    }

    @PostMapping("room/save")
    public String saveRoom(@AuthenticationPrincipal UserDetails userDetails,
            @ModelAttribute RoomPostDTO payload) throws IOException, UserNotFoundException {
        Set<Rule> rules = new HashSet<>();
        Set<Amentity> amenities = new HashSet<>();
        Set<Image> images = new HashSet<>();

        Iterator<Rule> itr = ruleService.listAllRule();
        while (itr.hasNext()) {
            rules.add(itr.next());
        }

        for (int i = 0; i < payload.getAmentities().length; i++) {
            amenities.add(new Amentity(payload.getAmentities()[i]));
        }

        for (int i = 0; i < payload.getImages().length; i++) {
            images.add(new Image(payload.getImages()[i]));
        }
        PriceType pt = Objects.equals(payload.getPriceType(), "PER_NIGHT") ? PriceType.PER_NIGHT : PriceType.PER_WEEK;
        Country country = new Country(payload.getCountry());

        // check if state exist
        State state = stateService.getStateByName(payload.getState());
        if (state == null)
            state = new State(payload.getState(), country);

        // check if city exist
        City city = cityService.getCityByName(payload.getCity());
        if (city == null)
            city = new City(payload.getCity(), state);

        User user = userService.get(payload.getHost());
        user.setRole(new Role(1));
        userService.saveUser(user);

        boolean status = user.isPhoneVerified();

        Room room = Room.builder().name(payload.getName()).accomodatesCount(payload.getAccomodatesCount())
                .bathroomCount(payload.getBathroomCount()).bedCount(payload.getBedCount())
                .bedroomCount(payload.getBedroomCount()).description(payload.getDescription()).amentities(amenities)
                .images(images).latitude(payload.getLatitude()).longitude(payload.getLongitude())
                .price(payload.getPrice()).priceType(pt).city(city)
                .state(state).country(country).rules(rules).host(new User(payload.getHost()))
                .roomGroup(new RoomGroup(payload.getRoomGroup())).priceType(PriceType.PER_NIGHT)
                .host(new User(payload.getHost())).category(new Category(payload.getCategory()))
                .currency(new Currency(payload.getCurrency())).privacyType(new RoomPrivacy(payload.getPrivacyType()))
                .thumbnail(images.iterator().next().getImage()).street(payload.getStreet()).status(status).build();

        Room savedRoom = roomService.save(room);

        /* MOVE IMAGE TO FOLDER */
        if (savedRoom != null) {
            String STATIC_PATH = "src/main/resources/static/room_images/";
            String uploadDir = STATIC_PATH + user.getEmail() + "/" + savedRoom.getId();
            String source = STATIC_PATH + user.getEmail() + "/";
            Path sourcePath = Paths.get(source);
            Path targetPath = Files.createDirectories(Paths.get(uploadDir));
            for (String imageName : payload.getImages()) {
                Files.move(sourcePath.resolve(imageName), targetPath.resolve(imageName),
                        StandardCopyOption.REPLACE_EXISTING);
            }
        }

        assert savedRoom != null;
        return savedRoom.getId() + "";
    }
}
