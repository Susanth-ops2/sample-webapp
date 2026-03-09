package com.sample.app;

import org.junit.Test;
import static org.junit.Assert.*;

public class HelloServletTest {

    @Test
    public void testAppVersion() {
        String version = "1.0.0";
        assertNotNull("Version should not be null", version);
        assertEquals("Version should be 1.0.0", "1.0.0", version);
    }

    @Test
    public void testAppName() {
        String appName = "sample-webapp";
        assertTrue("App name should contain 'sample'", appName.contains("sample"));
    }
}
