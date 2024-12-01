#include "Arduino.h"
#include "SPI.h"
#include "Wire.h"
// #include "XPowersLib.h" //https://github.com/lewisxhe/XPowersLib
#include "pins_config.h"

// #include "driver/spi_master.h"
// XPowersAXP2101 PMU;

/*----------------------------------------------------------------------*/
/*Transmission parameters*/

//TX frequency (MHZ - e6)
// #define FREQ  14.082e6
// #define RF_FREQ 10099 // 20850000
// #define RF_FREQ 20850000 // 20850000
uint32_t rf_freq = 20850000;

// offset RTTY
// #define OFFSET 170
uint32_t offset = 170;
/*----------------------------------------------------------------------*/

/*----------------------------------------------------------------------*/
/*Baudot code definitions*/
#define ARRAY_LEN 32
#define LETTERS_SHIFT 31
#define FIGURES_SHIFT 27
#define LINEFEED 2
#define CARRRTN  8

#define is_lowercase(ch)    ((ch) >= 'a' && (ch) <= 'z')
#define is_uppercase(ch)    ((ch) >= 'A' && (ch) <= 'Z')

char letters_arr[33] = "\000E\nA SIU\rDRJNFCKTZLWHYPQOBG\000MXV\000";
char figures_arr[33] = "\0003\n- \a87\r$4',!:(5\")2#6019?&\000./;\000";

enum baudot_mode {
  NONE,
  LETTERS,
  FIGURES
};
/*----------------------------------------------------------------------*/

void led_task(void *param);
void fpga_spi_blink(bool en);
void send_frequency(uint32_t&);

void rtty_txbit (int bit);
void rtty_txstring(char *str);
void rtty_txstring(String str);
void rtty_txbyte(uint8_t b);
uint8_t char_to_baudot(char c, char *array);

uint32_t freq_1 = 20850000; // 3316685096
uint32_t freq_2 = 20850100; // 3316669189

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
    // send_frequency(freq_1);
    // delay(50);                    // 20
    // PMU.setChargingLedMode(XPOWERS_CHG_LED_OFF);
    // fpga_spi_blink(false);
    // send_frequency(freq_2);
    // delay(50);       // random(300, 980)
    // Serial.printf("[BAT]:percent: %d%%\r\n", PMU.getBatteryPercent());

    rtty_txstring("RYRYRYRY THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG");
    delay(1000);
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

    buff[0] = fword       & 0xff;
    buff[1] = fword >>  8 & 0xff;
    buff[2] = fword >> 16 & 0xff;
    buff[3] = fword >> 24 & 0xff; // старший, передавать с него

    fpga_spi_blink(true);

    for(uint8_t i=0;i<4;++i){
        digitalWrite(PIN_FPGA_CS, 0);
        SPI.beginTransaction(SPISettings(1000000, SPI_MSBFIRST, SPI_MODE3));
        uint8_t fpga_output = SPI.transfer(buff[i]);
        SPI.endTransaction();
        digitalWrite(PIN_FPGA_CS, 1);
    }
}

//RTTY functions
/*----------------------------------------------------------------------*/
uint8_t char_to_baudot(char c, char *array)
{
  int i;
  for (i = 0; i < ARRAY_LEN; i++)
  {
    if (array[i] == c)
      return i;
  }

  return 0;
}

void rtty_txbyte(uint8_t b)
{
  int8_t i;

  rtty_txbit(0);

  /* TODO: I don't know if baudot is MSB first or LSB first */
  /* for (i = 4; i >= 0; i--) */
  for (i = 0; i < 5; i++)
  {
    if (b & (1 << i))
      rtty_txbit(1);
    else
      rtty_txbit(0);
  }

  rtty_txbit(1);
}

void rtty_txstring(String str)
{
  int len = str.length();
  char buf[len];
  str.toCharArray(buf, len);

  rtty_txstring(buf);
  
}

void rtty_txstring(char *str)
{
  enum baudot_mode current_mode = NONE;
  char c;
  uint8_t b;

  while (*str != '\0')
  {
    c = *str;
    /* some characters are available in both sets */
    if (c == '\n')
    {
      rtty_txbyte(LINEFEED);
    }
    else if (c == '\r')
    {
      rtty_txbyte(CARRRTN);
    }
    else if (is_lowercase(*str) || is_uppercase(*str))
    {
      if (is_lowercase(*str))
      {
        c -= 32;
      }

      if (current_mode != LETTERS)
      {
        rtty_txbyte(LETTERS_SHIFT);
        current_mode = LETTERS;
      }

      rtty_txbyte(char_to_baudot(c, letters_arr));
    }
    else
    {
      b = char_to_baudot(c, figures_arr);

      if (b != 0 && current_mode != FIGURES)
      {
        rtty_txbyte(FIGURES_SHIFT);
        current_mode = FIGURES;
      }

      rtty_txbyte(b);
    }

    str++;
  }
}



// Transmit a bit as a mark or space
void rtty_txbit (int bit) {
  if (bit) {
    // High - mark
    //digitalWrite(2, HIGH);
    //digitalWrite(3, LOW);

    // AD9850.wr_serial(0x00, FREQ+OFFSET);
    // gen.ApplySignal(SQUARE_WAVE,REG0,(RF_FREQ*1000ul)+OFFSET); // SINE_WAVE // SQUARE_WAVE // HALF_SQUARE_WAVE 
    // gen.EnableOutput(true);   // Turn ON the output - it defaults to OFF
    uint32_t local_rf_freq = rf_freq + offset;
    send_frequency(local_rf_freq);
  } 
  else {
    // Low - space
    //digitalWrite(3, HIGH);
    //digitalWrite(2, LOW);

    // AD9850.wr_serial(0x00, FREQ);
    // gen.ApplySignal(SQUARE_WAVE,REG0,(RF_FREQ*1000ul)); // SINE_WAVE // SQUARE_WAVE // HALF_SQUARE_WAVE 
    // gen.EnableOutput(true);   // Turn ON the output - it defaults to OFF
    send_frequency(rf_freq);
  }

  // Delay appropriately - tuned to 45.45 baud.

  delay(22); //sets the baud rate
  //delayMicroseconds(250);
}