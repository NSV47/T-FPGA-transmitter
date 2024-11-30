#include "Arduino.h"
#include "SPI.h"
#include "Wire.h"
// #include "XPowersLib.h" //https://github.com/lewisxhe/XPowersLib
#include "pins_config.h"

// #include "driver/spi_master.h"
// XPowersAXP2101 PMU;

void led_task(void *param);
void fpga_spi_blink(bool en);
void send_frequency(uint32_t&);

uint32_t freq_1 = 3316685096;
uint32_t freq_2 = 3316669189;

void setup()
{
    Serial.begin(115200);
    Serial.println("Hello T-FPGA-CORE");
    xTaskCreatePinnedToCore(led_task, "led_task", 1024, NULL, 1, NULL, 1);

    // bool result = PMU.begin(Wire, AXP2101_SLAVE_ADDRESS, PIN_IIC_SDA, PIN_IIC_SCL);
#if 0
    if (result == false) {
        Serial.println("PMU is not online...");
        while (1)
            delay(50);
    }
#endif
#if 0
    PMU.setDC4Voltage(1200);   // Here is the FPGA core voltage. Careful review of the manual is required before modification.
    PMU.setALDO1Voltage(3300); // BANK0 area voltage
    PMU.setALDO2Voltage(3300); // BANK1 area voltage
    PMU.setALDO3Voltage(2500); // BANK2 area voltage
    PMU.setALDO4Voltage(1800); // BANK3 area voltage

    PMU.enableALDO1();
    PMU.enableALDO2();
    PMU.enableALDO3();
    PMU.enableALDO4();

    PMU.disableTSPinMeasure();
    delay(1000);
#endif
    // Wire1.begin(PIN_FPGA_D0, PIN_FPGA_SCK);
    pinMode(PIN_FPGA_CS, OUTPUT);
    pinMode(PIN_BTN, INPUT);
    // SPI.begin(PIN_FPGA_SCK, PIN_FPGA_D1, PIN_FPGA_D0);
    SPI.begin(PIN_FPGA_SCK, PIN_FPGA_D0, PIN_FPGA_D1);
}

void loop()
{
    // PMU.setChargingLedMode(XPOWERS_CHG_LED_ON);
    // fpga_spi_blink(true);
    send_frequency(freq_1);
    delay(500);                    // 20
    // PMU.setChargingLedMode(XPOWERS_CHG_LED_OFF);
    // fpga_spi_blink(false);
    send_frequency(freq_2);
    delay(500);       // random(300, 980)
    // Serial.printf("[BAT]:percent: %d%%\r\n", PMU.getBatteryPercent());
}

void led_task(void *param)
{
    pinMode(PIN_LED, OUTPUT);
    while (true) {
        digitalWrite(PIN_LED, 1);
        delay(1000);                // 20
        digitalWrite(PIN_LED, 0);
        delay(1000);                // random(300, 980)
    }
}

void fpga_spi_blink(bool en)
{
    uint8_t fpga_input = en ? 0x01 : 0xf1;
    // uint8_t fpga_input = random(0, 0xfe);
    digitalWrite(PIN_FPGA_CS, 0);
    SPI.beginTransaction(SPISettings(1000000, SPI_MSBFIRST, SPI_MODE3));
    uint8_t fpga_output = SPI.transfer(fpga_input);
    SPI.endTransaction();
    digitalWrite(PIN_FPGA_CS, 1);
    // Serial.printf("input : %d  output : %d \r\n", fpga_input, fpga_output);
}

void send_frequency(uint32_t &freq){
    uint32_t fword;
    uint64_t tmp;
    tmp = (uint64_t)freq*(uint64_t)4294967296;
    fword = tmp / (uint32_t)27000000;

    uint8_t buff[4];

    buff[0] = freq       & 0xff;
    buff[1] = freq >>  8 & 0xff;
    buff[2] = freq >> 16 & 0xff;
    buff[3] = freq >> 24 & 0xff; // старший, передавать с него

    fpga_spi_blink(true);

    for(uint8_t i=0;i<4;++i){
        digitalWrite(PIN_FPGA_CS, 0);
        SPI.beginTransaction(SPISettings(1000000, SPI_MSBFIRST, SPI_MODE3));
        uint8_t fpga_output = SPI.transfer(buff[i]);
        SPI.endTransaction();
        digitalWrite(PIN_FPGA_CS, 1);
    }
}