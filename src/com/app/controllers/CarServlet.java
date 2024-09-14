package com.app;

import com.app.models.Car;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import com.google.gson.Gson;


@WebServlet("/api/cars/*")
public class CarServlet extends HttpServlet {
    private List<Car> carInventory = new ArrayList<>();
    private Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        Car CarOne = new Car(1, "Toyota", "Corolla", 20000);
            Car CarTwo = new Car(2, "Honda", "Civic", 25000);
            Car CarThree = new Car(3, "Ford", "Fiesta", 15000);
            Car CarFour = new Car(4, "Chevrolet", "Camaro", 30000);
                        
            carInventory.add(CarOne);            
            carInventory.add(CarTwo);
            carInventory.add(CarThree);
            carInventory.add(CarFour);

        String id = request.getPathInfo();
        if (id == null || id.equals("/")) {

            response.getWriter().write(gson.toJson(carInventory));

        } else {

            int carId = Integer.parseInt(id.substring(1));
            Car car = getCarById(carId);

            if (car != null) {
                
                response.getWriter().write(gson.toJson(car));

            } else {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                response.getWriter().write("{\"message\":\"Car not found\"}");
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Car newCar = gson.fromJson(request.getReader(), Car.class);
        carInventory.add(newCar);
        response.setStatus(HttpServletResponse.SC_CREATED);
        response.getWriter().write(gson.toJson(newCar));
    }

    private Car getCarById(int id) {
        return carInventory.stream().filter(car -> car.getId() == id).findFirst().orElse(null);
    }
}
