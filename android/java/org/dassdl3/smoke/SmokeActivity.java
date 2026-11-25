package org.dassdl3.smoke;

import org.libsdl.app.SDLActivity;

public final class SmokeActivity extends SDLActivity {
    @Override
    protected String[] getArguments() {
        String mode = getIntent().getStringExtra("mode");
        return mode == null ? new String[0] : new String[]{mode};
    }
}
